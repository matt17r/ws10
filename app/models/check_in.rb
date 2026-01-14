class CheckIn < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :user, uniqueness: { scope: :event_id, message: "already checked in to this event" }
  validates :checked_in_at, presence: true

  def self.token_for_event(event_number)
    salt = Rails.application.credentials.token_salt
    hash = Digest::MD5.hexdigest("checkin:#{event_number}:#{salt}")
    hash[0..7]
  end

  def self.valid_token?(token, event_number)
    token_for_event(event_number) == token
  end

  def self.token_path_for_event(event_number)
    "#{token_for_event(event_number)}/checkin"
  end
end
