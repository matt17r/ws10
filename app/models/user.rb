class User < ApplicationRecord
  has_secure_password
  attr_accessor :current_password

  has_many :sessions, dependent: :destroy
  has_many :assignments
  has_many :roles, through: :assignments, dependent: :destroy

  has_many :results, dependent: :destroy
  has_many :volunteers, dependent: :destroy

  generates_token_for :user_confirmation, expires_in: 1.hour

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, :display_name, :emoji, with: ->(value) { value.strip }

  validates :name, :display_name, :emoji, presence: true
  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }, presence: true, uniqueness: true
  validate :emoji_must_be_single_emoji

  def admin?
    roles.any? { |r| r.name == "Administrator" }
  end

  def organiser?
    roles.any? { |r| r.name == "Organiser" }
  end

  def confirm!
    return true if confirmed?
    update!(confirmed_at: Time.current)
  end

  def confirmed?
    confirmed_at.present?
  end

  def expiring_token
    generate_token_for(:user_confirmation)
  end

  def personal_best
    results.order(:time).first
  end

  def send_confirmation_email
    UsersMailer.account_confirmation(self).deliver_later
  end

  private

  def emoji_must_be_single_emoji
    matches = emoji.scan(Unicode::Emoji::REGEX)

    if matches.length != 1 || matches.first != emoji
      errors.add(:emoji, "must be a single emoji character from the approved (non-textual) set")
    end
  end
end
