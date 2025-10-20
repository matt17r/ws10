class Result < ApplicationRecord
  HOUR_MINUTES_SECONDS_REGEXP = /\A(?:(?<hours>[0-9]?[0-9]):)?(?<minutes>[0-5]?[0-9]):(?<seconds>[0-5]?[0-9])\z/
  MAXIMUM_TIME = 7200 # 2 hours
  MINIMUM_TIME = 1571 # 10_000m world record on a track is 26:11
  MAXIMUM_TIME_STRING = Time.at(MAXIMUM_TIME).utc.strftime("%k:%M:%S").freeze
  MINIMUM_TIME_STRING = Time.at(MINIMUM_TIME).utc.strftime("%M:%S").freeze

  belongs_to :user, counter_cache: true, optional: true
  belongs_to :event

  validate :user_or_time_present
  validate :no_setter_errors
  validates :user_id, uniqueness: { scope: :event_id, allow_nil: true, message: "already has a result for this event" }
  validates :time, numericality: {
    only_integer: true,
    greater_than: MINIMUM_TIME,
    less_than: MAXIMUM_TIME,
    allow_nil: true
  }

  def place
    return "P" if time.nil?
    event.results.where("time IS NOT NULL AND time < ?", time).count + 1
  end

  def pb?
    return false unless user
    return false if first_timer?
    previous_best = user.results.joins(:event).where("time IS NOT NULL AND events.number < ?", event.number).order(:time).first&.time
    time && (previous_best && time < previous_best) || time && !previous_best
  end

  def first_timer?
    return false unless user
    first_result = user.results.joins(:event).order(number: :asc).first
    self === first_result
  end

  def time_string
    return "Participant" unless time
    format_string = (time < 3600 ? "%M:%S" : "%k:%M:%S")
    Time.at(time).utc.strftime(format_string).strip
  end

  def time_string=(input)
    if input.blank? || input == "Participant"
      self.time = nil
      return
    end
    matches = HOUR_MINUTES_SECONDS_REGEXP.match(input.strip)
    raise ArgumentError if matches.nil?
    seconds = matches[:hours].to_i * 3600 + matches[:minutes].to_i * 60 + matches[:seconds].to_i
    raise ArgumentError if seconds <= MINIMUM_TIME || seconds >= MAXIMUM_TIME
    self.time = seconds
  rescue
    @setter_errors ||= {}
    @setter_errors[:time_string] ||= []
    @setter_errors[:time_string] << "must be a valid time greater than #{MINIMUM_TIME_STRING} and less than #{MAXIMUM_TIME_STRING}"
  end

  private

  def user_or_time_present
    if user.blank? && time.blank?
      errors.add(:base, "At least one of time or athlete must be present")
    end
  end

  def no_setter_errors
    return true if !@setter_errors || @setter_errors.empty?
    @setter_errors.each do |attribute, messages|
      messages.each do |message|
        errors.add(attribute, message)
      end
    end
  end
end
