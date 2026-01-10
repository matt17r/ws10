class UserBadge < ApplicationRecord
  belongs_to :user
  belongs_to :badge

  validates :earned_at, presence: true

  before_validation :set_earned_at, on: :create

  scope :recent, -> { where("earned_at > ?", 1.hour.ago) }
  scope :for_event, ->(event) {
    where("earned_at BETWEEN ? AND ?", event.updated_at - 1.hour, event.updated_at + 1.hour)
  }

  def display_name
    if badge.badge_family == "all-seasons"
      "#{badge.name} (#{earned_at.year})"
    else
      badge.name
    end
  end

  private

  def set_earned_at
    self.earned_at ||= Time.current
  end
end
