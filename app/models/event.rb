class Event < ApplicationRecord
    belongs_to :session
    validates :event_type, presence: true
  end