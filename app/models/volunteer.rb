class Volunteer < ApplicationRecord
  belongs_to :event
  belongs_to :user, counter_cache: true

  validates :role, presence: true
end
