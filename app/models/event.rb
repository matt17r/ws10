class Event < ApplicationRecord
  include HomeStatistics

  enum :status, { draft: "draft", in_progress: "in_progress", finalised: "finalised" }

  after_update :send_results_emails_if_finalised
  after_update :invalidate_statistics_cache_if_finalised

  belongs_to :location
  has_many :finish_positions
  has_many :finish_times
  has_many :finished_users, through: :finish_positions, source: :user
  has_many :results
  has_many :volunteers

  scope :not_finalised, -> { where.not(status: "finalised") }

  validates :date, presence: true
  validates :number, numericality: { only_integer: true, greater_than: 0 }
  validates :facebook_url, format: { with: URI::DEFAULT_PARSER.make_regexp, allow_blank: true }
  validates :strava_url, format: { with: URI::DEFAULT_PARSER.make_regexp, allow_blank: true }

  def self.next_event
    where("date >= ?", Date.today).order(:date).first
  end

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

  def active?
    in_progress?
  end

  def activate!
    Event.transaction do
      Event.where(status: "in_progress").where.not(id: id).update_all(status: "draft")
      update!(status: "in_progress")
    end
  end

  def deactivate!
    update!(status: "draft")
  end

  private

  def send_results_emails_if_finalised
    if saved_change_to_status? && finalised?
      # Award badges FIRST (background job)
      AwardBadgesJob.perform_later(id)

      # Then queue emails
      results.where.not(time: nil).includes(:user).find_each do |result|
        EventMailer.result_notification(result: result).deliver_later
      end

      results.where(time: nil).includes(:user).find_each do |result|
        EventMailer.participation_notification(result: result).deliver_later
      end
    end
  end

  def invalidate_statistics_cache_if_finalised
    if saved_change_to_status? && finalised?
      Event.invalidate_home_statistics_cache
    end
  end
end
