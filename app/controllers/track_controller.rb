class TrackController < ApplicationController
  def create
    payload = JSON.parse(request.raw_post) rescue {}
    batch = payload["batch"] || []

    return render json: { error: "Empty batch" }, status: :bad_request if batch.empty?

    ActiveRecord::Base.transaction do
      batch.each do |event_data|
        session_token = event_data["sessionId"] || event_data["session_token"]
        event_type    = event_data["type"] || event_data["event_type"]
        url           = event_data["url"]
        referrer      = event_data["referrer"]
        user_agent    = event_data["userAgent"] || event_data["user_agent"]
        data          = event_data["data"] || {}  # ← This is where country lives
        timestamp     = event_data["timestamp"]

        # --- Session handling ---
        session = Session.find_or_initialize_by(session_token: session_token)

        if session.new_record?
          # FIX: Use data["country"] not metadata["country"]
          session.country = data["country"] if data["country"]
          session.city = data["city"] if data["city"]
          session.initial_referrer = referrer if referrer.present?
          session.user_agent = user_agent
        else
          session.touch
        end

        session.save! if session.changed?

        # --- Event creation ---
        created_time = begin
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
          metadata: data,  # ← Store the data as metadata
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