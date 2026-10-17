class Event < ApplicationRecord
  include HomeStatistics

  CHECK_IN_TIME_ZONE = ActiveSupport::TimeZone["Sydney"]

  enum :status, { draft: "draft", in_progress: "in_progress", finalised: "finalised", abandoned: "abandoned", cancelled: "cancelled" }

  after_update :send_results_emails_if_finalised
  after_update :invalidate_statistics_cache_if_finalised

  belongs_to :location
  has_many :finish_positions
  has_many :finish_times
  has_many :finished_users, through: :finish_positions, source: :user
  has_many :results
  has_many :user_badges
  has_many :volunteers
  has_many :check_ins
  has_many :checked_in_users, through: :check_ins, source: :user
  has_one_attached :og_image

  scope :not_finalised, -> { where.not(status: [ "finalised", "abandoned", "cancelled" ]) }
  scope :public_visible, -> { where(status: [ "in_progress", "finalised", "abandoned", "cancelled" ]) }
  scope :upcoming_for_home, -> { where.not(status: [ "finalised", "cancelled" ]) }

  normalizes :notice, with: -> { _1.presence }

  validates :date, presence: true
  validates :facebook_url, format: { with: URI::DEFAULT_PARSER.make_regexp, allow_blank: true }
  validates :notice, presence: true, allow_nil: true
  validates :number, numericality: { only_integer: true, greater_than: 0 }
  validates :strava_url, format: { with: URI::DEFAULT_PARSER.make_regexp, allow_blank: true }

  def self.next_event
    where("date >= ?", Date.today).order(:date).first
  end

  def self.open_for_check_in(at = Time.current)
    where(status: "in_progress").or(where(date: check_in_date(at))).order(:date).find { |event| event.open_for_check_in?(at) }
  end

  def self.accepting_late_check_ins(at = Time.current)
    latest = where(date: ..check_in_date(at)).order(date: :desc).first
    latest if latest&.accepting_late_check_ins?(at)
  end

  def self.next_for_check_in(at = Time.current)
    where(date: check_in_date(at)..).where.not(status: [ "abandoned", "cancelled" ]).order(:date).find { |event| at < event.check_in_closes_at }
  end

  def self.ready_to_close_out(at = Time.current)
    not_finalised.where(date: check_in_date(at) - 1)
  end

  def self.check_in_date(at)
    at.in_time_zone(CHECK_IN_TIME_ZONE).to_date
  end
  private_class_method :check_in_date

  def has_social_links?
    facebook_url.present? || strava_url.present?
  end

  def to_s
    "##{number} - #{date.to_fs(:short)}"
  end

  def to_param
    number.to_s
  end

  def unplaced_users
    User.where.not(id: finished_users.select(:id)).order(Arel.sql("LOWER(name) ASC")).left_joins(:results).select("users.*, COUNT(results.id) AS results_count").group("users.id").order("users.name")
  end

  def checked_in_unplaced_users
    checked_in_users.where.not(id: finished_users.select(:id)).order(Arel.sql("LOWER(name) ASC")).left_joins(:results).select("users.*, COUNT(results.id) AS results_count").group("users.id").order("users.name")
  end

  def active?
    in_progress?
  end

  def check_in_opens_at
    CHECK_IN_TIME_ZONE.local(date.year, date.month, date.day, 6, 30)
  end

  def check_in_closes_at
    CHECK_IN_TIME_ZONE.local(date.year, date.month, date.day, 22, 0)
  end

  def open_for_check_in?(at = Time.current)
    return false if abandoned? || cancelled?
    in_progress? || (check_in_opens_at...check_in_closes_at).cover?(at)
  end

  def accepting_late_check_ins?(at = Time.current)
    return false if abandoned? || cancelled? || open_for_check_in?(at)
    at >= check_in_closes_at
  end

  def not_finalised?
    draft? || in_progress?
  end

  def activate!
    raise "Cannot activate an abandoned or cancelled event" if abandoned? || cancelled?
    Event.transaction do
      Event.where(status: "in_progress").where.not(id: id).update_all(status: "draft")
      update!(status: "in_progress")
    end
  end

  def deactivate!
    update!(status: "draft")
  end

  def abandon!
    raise "Cannot abandon a finalised event" if finalised?
    update!(status: "abandoned")
  end

  def archive_as_cancelled!
    raise "Can only archive abandoned events" unless abandoned?
    update!(status: "cancelled")
    GenerateOgImageJob.perform_later(id)
  end

  private

  def send_results_emails_if_finalised
    if saved_change_to_status? && finalised?
      # Award badges FIRST, then generate OG image (chained from AwardBadgesJob)
      AwardBadgesJob.perform_later(id)

      # Then queue emails
      results.where.not(user_id: nil).includes(:user).find_each do |result|
        EventMailer.thanks_notification(result: result).deliver_later
      end

      volunteers.includes(:user).find_each do |volunteer|
        EventMailer.volunteer_notification(volunteer: volunteer).deliver_later
      end
    end
  end

  def invalidate_statistics_cache_if_finalised
    if saved_change_to_status? && finalised?
      Event.invalidate_home_statistics_cache
    end
  end
end
