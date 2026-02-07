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
  has_many :finish_positions, dependent: :destroy
  has_many :check_ins, dependent: :destroy
  has_many :user_badges, dependent: :destroy
  has_many :badges, through: :user_badges

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

  scope :never_confirmed, -> {
    where(confirmed_at: nil)
      .where("created_at < ?", 30.days.ago)
  }

  scope :confirmed_but_inactive, -> {
    cutoff_date = 12.months.ago

    where("confirmed_at IS NOT NULL")
      .where("confirmed_at < ?", cutoff_date)
      .where.not(id: User.joins("LEFT JOIN results ON results.user_id = users.id")
                           .joins("LEFT JOIN volunteers ON volunteers.user_id = users.id")
                           .joins("LEFT JOIN check_ins ON check_ins.user_id = users.id")
                           .joins("LEFT JOIN events AS result_events ON result_events.id = results.event_id")
                           .joins("LEFT JOIN events AS volunteer_events ON volunteer_events.id = volunteers.event_id")
                           .joins("LEFT JOIN events AS checkin_events ON checkin_events.id = check_ins.event_id")
                           .where("result_events.date >= ? OR volunteer_events.date >= ? OR check_ins.checked_in_at >= ?",
                                  cutoff_date, cutoff_date, cutoff_date)
                           .select("users.id"))
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

  def self.find_by_barcode(barcode)
    return nil if barcode.blank?

    user_id = case barcode.to_s.strip
    when /\AA(\d+)\z/i then $1.to_i
    when /\A\d+\z/ then barcode.to_i
    end

    find_by(id: user_id) if user_id
  end

  def self.find_by_barcode!(barcode)
    find_by_barcode(barcode) || raise(ActiveRecord::RecordNotFound, "No user found with barcode: #{barcode}")
  end

  private

  def emoji_must_be_single_emoji
    matches = emoji.scan(Unicode::Emoji::REGEX)

    if matches.length != 1 || matches.first != emoji
      errors.add(:emoji, "must be a single emoji character from the approved (non-textual) set")
    end
  end
end
