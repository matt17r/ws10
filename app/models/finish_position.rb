class FinishPosition < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :event

  validates :position, numericality: {
    only_integer: true,
    greater_than: 0,
    allow_nil: true
  }
  validates :position, uniqueness: { scope: :event_id, message: "is already taken" }
  validates :user, uniqueness: { scope: :event_id, message: "already has a position" }, if: -> { user.present? }

  def user_name
    user&.name_with_display_name || "Unknown"
  end
end
