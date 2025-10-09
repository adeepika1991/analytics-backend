class ApplicationController < ActionController::API
  def debug
    # Test database connection
    ActiveRecord::Base.connection.execute("SELECT 1 as test")

    render json: {
      status: "healthy",
      database: "connected",
      database_url: ActiveRecord::Base.connection_db_config.url.gsub(/:(.*)@/, ':****@'),
      timestamp: Time.current.utc.iso8601
    }
  rescue StandardError => e
    render json: {
      status: "unhealthy",
      error: e.message,
      database_url: ActiveRecord::Base.connection_db_config.url.gsub(/:(.*)@/, ':****@'),
      timestamp: Time.current.utc.iso8601
    }, status: 500
  end
  end
