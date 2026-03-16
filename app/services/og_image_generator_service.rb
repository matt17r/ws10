class OgImageGeneratorService
  WIDTH = 1200
  HEIGHT = 630

  def initialize(event)
    @event = event
  end

  def generate_and_attach
    png_data = render_png
    @event.og_image.attach(
      io: StringIO.new(png_data),
      filename: "event-#{@event.number}-og.png",
      content_type: "image/png"
    )
  end

  def stats
    @stats ||= compute_stats
  end

  def build_svg
    s = stats
    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="#{WIDTH}" height="#{HEIGHT}" viewBox="0 0 #{WIDTH} #{HEIGHT}">
        <defs>
          <linearGradient id="headerGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stop-color="#9DA39A"/>
            <stop offset="45%" stop-color="#B98389"/>
            <stop offset="100%" stop-color="#DB2955"/>
          </linearGradient>
          <linearGradient id="accentGrad" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stop-color="#DB2955"/>
            <stop offset="100%" stop-color="#B91E47"/>
          </linearGradient>
        </defs>

        <!-- Background -->
        <rect width="#{WIDTH}" height="#{HEIGHT}" fill="#FFFFFF"/>

        <!-- Header -->
        <rect width="#{WIDTH}" height="195" fill="url(#headerGrad)"/>
        <rect width="#{WIDTH}" height="6" fill="url(#accentGrad)"/>

        <!-- Header text: WS10 brand -->
        <text x="52" y="88" font-family="sans-serif" font-weight="900" font-size="58" fill="white" letter-spacing="-1">Western Sydney 10</text>

        <!-- Header text: Event number -->
        <text x="1148" y="88" font-family="sans-serif" font-weight="900" font-size="58" fill="white" text-anchor="end" letter-spacing="-1">Event ##{escape s[:event_number]}</text>

        <!-- Header text: Date and location -->
        <text x="52" y="148" font-family="sans-serif" font-size="28" fill="rgba(255,255,255,0.88)">#{escape s[:date_str]}</text>
        <text x="1148" y="148" font-family="sans-serif" font-size="28" fill="rgba(255,255,255,0.88)" text-anchor="end">#{escape s[:location_name]}</text>

        <!-- Stats row: 3 cards -->
        #{stat_card(x: 40, label: "RUNNERS", value: s[:participant_count], color: "#DB2955", bg: "#FDF4F7")}
        #{stat_card(x: 420, label: "FIRST TIMERS", value: s[:first_timer_count], color: "#9DA39A", bg: "#F5F6F5")}
        #{stat_card(x: 800, label: "PERSONAL BESTS", value: s[:pb_count], color: "#B98389", bg: "#FBF7F7")}

        <!-- Bottom row: Records (left) + Badges (right) -->
        <rect x="40" y="415" width="530" height="175" rx="12" fill="#F8F9FA"/>
        <rect x="40" y="415" width="530" height="5" rx="12" fill="url(#accentGrad)"/>

        <rect x="630" y="415" width="530" height="175" rx="12" fill="#F8F9FA"/>
        <rect x="630" y="415" width="530" height="5" rx="12" fill="#9DA39A"/>

        #{records_section(s)}
        #{badges_section(s)}

        <!-- Footer -->
        <text x="600" y="618" font-family="sans-serif" font-size="20" fill="#9DA39A" text-anchor="middle" letter-spacing="2">ws10.run</text>
      </svg>
    SVG
  end

  private

  def render_png
    require "vips"
    svg = build_svg
    img = Vips::Image.svgload_buffer(svg.b, dpi: 144)
    img = img.flatten(background: [ 255, 255, 255 ])
    img.write_to_buffer(".png")
  end

  def stat_card(x:, label:, value:, color:, bg:)
    card_width = 340
    card_height = 185
    y = 215
    center_x = x + card_width / 2

    <<~SVG
      <rect x="#{x}" y="#{y}" width="#{card_width}" height="#{card_height}" rx="12" fill="#{bg}"/>
      <rect x="#{x}" y="#{y}" width="#{card_width}" height="5" rx="12" fill="#{color}"/>
      <text x="#{center_x}" y="#{y + 90}" font-family="sans-serif" font-weight="900" font-size="68" fill="#{color}" text-anchor="middle">#{value}</text>
      <text x="#{center_x}" y="#{y + 140}" font-family="sans-serif" font-size="20" fill="#7E8287" text-anchor="middle" letter-spacing="2">#{label}</text>
    SVG
  end

  def records_section(s)
    lines = []

    if s[:new_ws10_record]
      lines << { text: "★  NEW WS10 RECORD", color: "#DB2955", size: 22, bold: true }
      lines << { text: s[:fastest_time_str], color: "#54494B", size: 36, bold: true }
    elsif s[:new_course_record]
      lines << { text: "★  NEW COURSE RECORD", color: "#DB2955", size: 22, bold: true }
      lines << { text: s[:fastest_time_str], color: "#54494B", size: 36, bold: true }
    elsif s[:course_record_str]
      lines << { text: "Course best:", color: "#7E8287", size: 20, bold: false }
      lines << { text: s[:course_record_str], color: "#54494B", size: 36, bold: true }
    else
      lines << { text: "First event at this course", color: "#7E8287", size: 20, bold: false }
    end

    base_x = 52
    base_y = 455
    line_height = 42
    svg = +""

    svg << "<text x=\"#{base_x}\" y=\"#{base_y - 8}\" font-family=\"sans-serif\" font-size=\"16\" fill=\"#9DA39A\" letter-spacing=\"3\">RECORDS</text>\n"

    lines.each_with_index do |line, i|
      weight = line[:bold] ? "bold" : "normal"
      svg << "<text x=\"#{base_x}\" y=\"#{base_y + 25 + i * line_height}\" font-family=\"sans-serif\" font-weight=\"#{weight}\" font-size=\"#{line[:size]}\" fill=\"#{line[:color]}\">#{escape line[:text]}</text>\n"
    end

    svg
  end

  def badges_section(s)
    base_x = 642
    base_y = 455
    line_height = 34
    svg = +""

    svg << "<text x=\"#{base_x}\" y=\"#{base_y - 8}\" font-family=\"sans-serif\" font-size=\"16\" fill=\"#9DA39A\" letter-spacing=\"3\">BADGES AWARDED</text>\n"

    if s[:badge_count] == 0
      svg << "<text x=\"#{base_x}\" y=\"#{base_y + 40}\" font-family=\"sans-serif\" font-size=\"28\" fill=\"#54494B\">None this event</text>\n"
    else
      svg << "<text x=\"#{base_x}\" y=\"#{base_y + 40}\" font-family=\"sans-serif\" font-weight=\"bold\" font-size=\"44\" fill=\"#DB2955\">#{s[:badge_count]}</text>\n"
      svg << "<text x=\"#{base_x + 62}\" y=\"#{base_y + 40}\" font-family=\"sans-serif\" font-size=\"24\" fill=\"#54494B\"> badges earned</text>\n"

      s[:badge_families].first(3).each_with_index do |family, i|
        svg << "<text x=\"#{base_x}\" y=\"#{base_y + 82 + i * line_height}\" font-family=\"sans-serif\" font-size=\"20\" fill=\"#7E8287\">#{escape humanize_family(family)}</text>\n"
      end

      if s[:badge_families].size > 3
        remaining = s[:badge_families].size - 3
        svg << "<text x=\"#{base_x}\" y=\"#{base_y + 82 + 3 * line_height}\" font-family=\"sans-serif\" font-size=\"18\" fill=\"#9DA39A\">+ #{remaining} more</text>\n"
      end
    end

    svg
  end

  def compute_stats
    results = @event.results.includes(:user).to_a
    timed_results = results.select { |r| r.time.present? }

    participant_count = results.count + @event.volunteers.count
    first_timer_count = results.count { |r| r.user && r.first_timer? }
    pb_count = timed_results.count { |r| r.user && r.pb? }

    fastest_time = timed_results.min_by(&:time)&.time
    fastest_time_str = fastest_time ? format_time(fastest_time) : nil

    course_record = fastest_time ? course_record_time : nil
    new_course_record = fastest_time && (course_record.nil? || fastest_time < course_record)

    ws10_record = fastest_time ? ws10_record_time : nil
    new_ws10_record = fastest_time && (ws10_record.nil? || fastest_time < ws10_record)

    badge_records = UserBadge.where(event_id: @event.id).includes(:badge)
    badge_families = badge_records.map { |ub| ub.badge.badge_family }.uniq.sort

    {
      event_number: @event.number,
      date_str: @event.date.strftime("%-d %B %Y"),
      location_name: @event.location.name,
      participant_count: participant_count,
      first_timer_count: first_timer_count,
      pb_count: pb_count,
      fastest_time_str: fastest_time_str,
      course_record_str: course_record ? format_time(course_record) : nil,
      new_course_record: new_course_record,
      new_ws10_record: new_ws10_record,
      badge_count: badge_records.count,
      badge_families: badge_families
    }
  end

  def course_record_time
    Result.joins(:event)
          .where("events.location_id = ? AND events.number < ?", @event.location_id, @event.number)
          .where.not(time: nil)
          .minimum(:time)
  end

  def ws10_record_time
    Result.joins(:event)
          .where("events.number < ?", @event.number)
          .where.not(time: nil)
          .minimum(:time)
  end

  def format_time(seconds)
    return "" unless seconds
    Time.at(seconds).utc.strftime(seconds < 3600 ? "%M:%S" : "%-H:%M:%S")
  end

  def humanize_family(family)
    family.split("-").map(&:capitalize).join(" ")
  end

  def escape(str)
    str.to_s
       .gsub("&", "&amp;")
       .gsub("<", "&lt;")
       .gsub(">", "&gt;")
       .gsub('"', "&quot;")
  end
end
