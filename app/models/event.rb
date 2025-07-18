class Event < ApplicationRecord
  after_update :send_results_emails_if_ready

  has_many :finish_positions
  has_many :finish_times
  has_many :finished_users, through: :finish_positions, source: :user
  has_many :results
  has_many :volunteers

  scope :in_progress, -> { where(results_ready: false) }

  validates :date, presence: true
  validates :location, presence: true
  validates :number, numericality: { only_integer: true, greater_than: 0 }

  def to_s
    "##{number} - #{date.to_fs(:short)}"
  end

  def to_param
    number.to_s
  end

  def unplaced_users
    User.where.not(id: finished_users.select(:id)).order(Arel.sql("LOWER(name) ASC")).left_joins(:results).select("users.*, COUNT(results.id) AS results_count").group("users.id").order("users.name")
  end

  private

  def send_results_emails_if_ready
    if saved_change_to_results_ready? && results_ready?
      results.where.not(time: nil).includes(:user).find_each do |result|
        EventMailer.result_notification(result: result).deliver_later
      end

      results.where(time: nil).includes(:user).find_each do |result|
        EventMailer.participation_notification(result: result).deliver_later
      end
    end
  end
end
