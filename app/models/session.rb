class Session < ApplicationRecord
    validates :session_token, presence: true, uniqueness: true
  
    # helper method to mark session active
    def active?
      updated_at && updated_at > 30.seconds.ago
    end
  end