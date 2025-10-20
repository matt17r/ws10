class Volunteer < ApplicationRecord
  belongs_to :event
  belongs_to :user, counter_cache: true

  scope :by_role, -> { order(:role).includes(:user) }

  validates :role, presence: true
end
