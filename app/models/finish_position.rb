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

  def self.token_prefix_for_position(position)
    salt = Rails.application.credentials.token_salt
    hash = Digest::MD5.hexdigest("#{position}:#{salt}")
    hash[0..3]
  end

  def self.valid_token?(prefix, position)
    token_prefix_for_position(position) == prefix
  end

  def self.token_path_for_position(position)
    prefix = token_prefix_for_position(position)
    position_str = format("%03d", position)
    "#{prefix}/#{position_str}"
  end

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
