class TrackController < ApplicationController
  # skip_before_action :verify_authenticity_token

  def create
    payload = JSON.parse(request.raw_post) rescue {}
    batch = payload["batch"] || []

    return render json: { error: "Empty batch" }, status: :bad_request if batch.empty?

    ActiveRecord::Base.transaction do
      batch.each do |event_data|
        # Normalize keys
        session_token = event_data["sessionId"] || event_data["session_token"]
        event_type    = event_data["type"] || event_data["event_type"]
        url           = event_data["url"]
        referrer      = event_data["referrer"]
        user_agent    = event_data["userAgent"] || event_data["user_agent"]
        metadata      = event_data["data"] || {}
        timestamp     = event_data["timestamp"]

        # --- 1. Session handling ---
        session = Session.find_or_initialize_by(session_token: session_token)

        if session.new_record?
          session.country = metadata["country"] if metadata["country"]
          session.city = metadata["city"] if metadata["city"]
          session.initial_referrer = referrer if referrer.present?
          session.user_agent = user_agent
        else
          session.touch # refresh last_updated_at
        end

        session.save! if session.changed?

        # --- 2. Event creation ---
        created_time =
          begin
            timestamp.present? ? DateTime.parse(timestamp) : Time.current
          rescue
            Time.current
          end

        Event.create!(
          session_id: session.id,
          event_type: event_type,
          url: url,
          referrer: referrer,
          user_agent: user_agent,
          metadata: metadata,
          created_at: created_time
        )
      end
    end

    render json: { ok: true }, status: :ok

  rescue => e
    Rails.logger.error "[Track] #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")
    render json: { error: e.message }, status: :internal_server_error
  end
end
