require "csv"

class User < ApplicationRecord
  include Barcodeable

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

  scope :with_activity, -> {
    joins("LEFT JOIN results ON results.user_id = users.id")
      .joins("LEFT JOIN volunteers ON volunteers.user_id = users.id")
      .where("results.id IS NOT NULL OR volunteers.id IS NOT NULL")
      .select("users.*,
               COUNT(DISTINCT COALESCE(results.event_id, volunteers.event_id)) as total_events_count,
               COUNT(DISTINCT results.id) as runs_count,
               COUNT(DISTINCT volunteers.id) as volunteers_count,
               MIN(CASE WHEN results.time IS NOT NULL THEN results.time END) as best_time,
               CASE
                 WHEN MIN(CASE WHEN results.time IS NOT NULL THEN results.time END) IS NULL
                 THEN 999999
                 ELSE MIN(CASE WHEN results.time IS NOT NULL THEN results.time END)
               END as best_time_with_nulls_last")
      .group("users.id")
  }

  scope :sorted_by, ->(column, direction = nil) {
    allowed_sorts = {
      "display_name" => "LOWER(users.display_name)",
      "events" => "total_events_count",
      "runs" => "runs_count",
      "volunteers" => "volunteers_count",
      "personal_best" => "best_time_with_nulls_last"
    }

    sort_sql = allowed_sorts[column.to_s] || "LOWER(users.display_name)"

    default_direction = %w[events runs volunteers].include?(column.to_s) ? "desc" : "asc"
    sort_direction = direction.to_s.downcase == "desc" ? "desc" : default_direction

    order("#{sort_sql} #{sort_direction}")
  }

  def admin?
    roles.any? { |r| r.name == "Administrator" }
  end

  def barcode_string
    "A#{sprintf("%06d", id)}"
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

  def organiser?
    roles.any? { |r| r.name == "Organiser" }
  end

  def personal_best
    results.where.not(time: nil).order(:time).first
  end

  def send_confirmation_email
    UsersMailer.account_confirmation(self).deliver_later
  end

  def name_with_display_name
    "#{name} (#{display_name})"
  end

  def self.csv_template
    csv_data = CSV.generate(headers: true) do |csv|
      csv << [ "email_address", "name", "display_name" ]
      csv << [ "jane@example.com", "Jane Doe", "Jane" ]
      csv << [ "john@example.com", "John Smith", "John" ]
    end
  end

  private

  def emoji_must_be_single_emoji
    matches = emoji.scan(Unicode::Emoji::REGEX)

    if matches.length != 1 || matches.first != emoji
      errors.add(:emoji, "must be a single emoji character from the approved (non-textual) set")
    end
  end
end
