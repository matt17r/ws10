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

  def og_event_description(event)
    return "This event was cancelled." if event.cancelled?

    s = OgImageGeneratorService.new(event).stats
    parts = [ "#{s[:participant_count]} #{'finisher'.pluralize(s[:participant_count])}" ]
    parts << "#{s[:first_timer_count]} first #{'timer'.pluralize(s[:first_timer_count])}" if s[:first_timer_count] > 0
    parts << "#{s[:pb_count]} personal #{'best'.pluralize(s[:pb_count])}" if s[:pb_count] > 0
    if s[:new_ws10_record]
      parts << "New WS10 record: #{s[:fastest_time_str]}"
    elsif s[:new_course_record]
      parts << "New course record: #{s[:fastest_time_str]}"
    elsif s[:fastest_time_str]
      parts << "First finisher: #{s[:fastest_time_str]}"
    end
    parts.join(" · ")
  end
end
