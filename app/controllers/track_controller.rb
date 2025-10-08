class TrackController < ApplicationController
    def create
      # Log incoming events (for now)
      puts "📦 Received batch: #{params.inspect}"
  
      render json: { status: "ok", message: "Event received" }, status: :ok
    end
  end