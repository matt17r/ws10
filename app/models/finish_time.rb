class FinishTime < ApplicationRecord
  belongs_to :event

  validates :position, numericality: {
    only_integer: true,
    greater_than: 0,
    allow_nil: true
  }
  validates :position, uniqueness: { scope: :event_id, message: "is already taken" }
  validates :time, allow_nil: true, numericality: {
    only_integer: true,
    greater_than: Result::MINIMUM_TIME,
    less_than: Result::MAXIMUM_TIME
  }

  def time_string
    return "Participant" if time.nil?
    format_string = (time < 3600 ? "%M:%S" : "%k:%M:%S")
    Time.at(time).utc.strftime(format_string).strip
  end

  def time_string=(input)
    return self.time = nil if input == "P"
    matches = Result::HOUR_MINUTES_SECONDS_REGEXP.match(input.strip)
    raise ArgumentError if matches.nil?
    total_seconds = matches[:hours].to_i * 3600 + matches[:minutes].to_i * 60 + matches[:seconds].to_i
    raise ArgumentError if total_seconds <= Result::MINIMUM_TIME || total_seconds >= Result::MAXIMUM_TIME
    self.time = total_seconds
  rescue
    @setter_errors ||= {}
    @setter_errors[:time_string] ||= []
    @setter_errors[:time_string] << "must be a valid time greater than #{Result::MINIMUM_TIME_STRING} and less than #{Result::MAXIMUM_TIME_STRING}"
  end
end
