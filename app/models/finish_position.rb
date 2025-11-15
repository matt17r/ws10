class FinishPosition < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :event

  validates :position, numericality: {
    only_integer: true,
    greater_than: 0,
    allow_nil: true
  }
  validates :position, uniqueness: { scope: :event_id, message: "is already taken", allow_nil: true }
  validates :user, uniqueness: { scope: :event_id, message: "already has a position" }, if: -> { user.present? }
  validate :user_or_position_must_be_present

  def user_name
    user&.name_with_display_name || "Unknown"
  end

  def known_user?
    user.present?
  end

  private

  def user_or_position_must_be_present
    if user.blank? && position.blank?
      errors.add(:base, "Must have either a user or a position")
    end
  end
end
