class StreamController < ApplicationController
  include ActionController::Live

  SSE_SLEEP_INTERVAL = 5

  def index
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control']  = 'no-cache'
    response.headers['Connection']     = 'keep-alive'
    response.headers['X-Accel-Buffering'] = 'no'
    # allow CORS for testing; production: restrict to dashboard origin
    response.headers['Access-Control-Allow-Origin'] = '*'

    stream = response.stream

    begin
      # Send an initial payload immediately (helps debugging)
      stream.write("data: #{initial_payload.to_json}\n\n")

      loop do
        payload = safe_gather_metrics
        stream.write("data: #{payload.to_json}\n\n")
        stream.write(": heartbeat\n\n")
        sleep SSE_SLEEP_INTERVAL
      end
    rescue IOError
      # client disconnected — nothing to do
    rescue => e
      Rails.logger.error "[Stream] uncaught exception: #{e.class} #{e.message}\n#{e.backtrace.first(10).join("\n")}"
    ensure
      stream.close
    end
  end

  private

  def initial_payload
    { timestamp: Time.current.utc.iso8601, message: "stream-open" }
  end

  # wrapper that returns a safe payload even if part of it fails
  def safe_gather_metrics
    {
      timestamp: Time.current.utc.iso8601,
      active_users: safe_active_user_count,
      visits_last_min: safe_count_events_last_min,
      top_clicks: safe_top_clicks(5),
      recent_events: safe_recent_events(25)
    }
  rescue => e
    Rails.logger.error "[Stream#safe_gather_metrics] #{e.class}: #{e.message}"
    { error: "metrics_error", timestamp: Time.current.utc.iso8601 }
  end

  def last_seen_column
    @last_seen_column ||= begin
      if ActiveRecord::Base.connection.column_exists?(:sessions, :last_seen)
        "last_seen"
      else
        "updated_at"
      end
    rescue => e
      Rails.logger.error "[Stream] column check failed: #{e.class}: #{e.message}"
      "updated_at"
    end
  end

  def safe_active_user_count
    # col = last_seen_column
    # Session.where("#{col} > ?", 30.seconds.ago).count
    Session.where(last_seen_column => 30.seconds.ago..).count
  end

  def safe_count_events_last_min
    Event.where("created_at >= ?", 1.minute.ago).count
  end

  def safe_top_clicks(limit = 5)
    result = Event.where(event_type: 'click')
                  .group("metadata ->> 'label'")
                  .order("count_all DESC")
                  .limit(limit)
                  .count
    result.map { |label, count| { label: (label || 'unknown'), count: count } }
  end

  def safe_recent_events(limit = 25)
    Event.includes(:session)
         .order(created_at: :desc)
         .limit(limit)
         .map do |ev|
      {
        id: ev.id,
        type: ev.event_type,
        timestamp: ev.created_at.utc.iso8601,
        url: ev.url,
        referrer: ev.referrer,
        metadata: ev.metadata,
        session_token: ev.session&.session_token
      }
    end
  end
end
