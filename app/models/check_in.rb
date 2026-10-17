class CheckIn < ApplicationRecord
  belongs_to :user
  belongs_to :event

  enum :status, { approved: "approved", pending: "pending" }, validate: true

  validates :user, uniqueness: { scope: :event_id, message: "already checked in to this event" }
  validates :checked_in_at, presence: true

  def self.check_in!(event:, user:, status: "approved")
    check_in = new(event: event, user: user, status: status, checked_in_at: Time.current)

    transaction do
      check_in.save!
      Result.find_or_create_by!(event: event, user: user) if check_in.approved?
    end

    check_in
  end

  def record_time!(time_string)
    result = Result.find_or_initialize_by(event: event, user: user)
    result.time_string = time_string
    result.validate!

    if approved?
      result.save!
    else
      update!(submitted_time: result.time)
    end
  end

  def recorded_time_string
    time = approved? ? Result.find_by(event: event, user: user)&.time : submitted_time
    Result.new(time: time).time_string if time
  end

  def approve!
    transaction do
      Result.find_or_create_by!(event: event, user: user) { |result| result.time = submitted_time }
      approved!
    end
  end

  def submitted_time_string
    Result.new(time: submitted_time).time_string
  end

  def withdraw!
    transaction do
      Result.where(event: event, user: user).destroy_all if approved?
      destroy!
    end
  end
end
