module ApplicationHelper
  def format_pace_time(seconds)
    return "N/A" if seconds.nil?
    format_string = (seconds < 3600 ? "%M:%S" : "%k:%M:%S")
    Time.at(seconds).utc.strftime(format_string).strip
  end

  def format_total_time(seconds)
    return "0h" if seconds.nil? || seconds.zero?

    days = seconds / 86400
    hours = (seconds % 86400) / 3600
    minutes = (seconds % 3600) / 60

    parts = []
    parts << "#{days}d" if days > 0
    parts << "#{hours}h" if hours > 0
    parts << "#{minutes}m" if minutes > 0 && days.zero?

    parts.join(" ")
  end

  def repeat_runner?
    authenticated? && Current.user.results.count >= 3
  end
end
