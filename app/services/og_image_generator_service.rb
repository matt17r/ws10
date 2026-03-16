class OgImageGeneratorService
  WIDTH = 1200
  HEIGHT = 630

  BADGE_LEVEL_ORDER = { "singular" => 4, "gold" => 3, "silver" => 2, "bronze" => 1 }.freeze
  BADGE_COLORS = {
    "gold" => "#FFD700",
    "silver" => "#C0C0C0",
    "bronze" => "#CD7F32",
    "singular" => "#DB2955"
  }.freeze

  ICON_USER_GROUP = "M18 18.72a9.094 9.094 0 0 0 3.741-.479 3 3 0 0 0-4.682-2.72m.94 " \
    "3.198.001.031c0 .225-.012.447-.037.666A11.944 11.944 0 0 1 12 21c-2.17 0-4.207-.576-5.963-1.584A6.062 " \
    "6.062 0 0 1 6 18.719m12 0a5.971 5.971 0 0 0-.941-3.197m0 0A5.995 5.995 0 0 0 12 12.75a5.995 5.995 0 " \
    "0 0-5.058 2.772m0 0a3 3 0 0 0-4.681 2.72 8.986 8.986 0 0 0 3.74.477m.94-3.197a5.971 5.971 0 " \
    "0 0-.94 3.197M15 6.75a3 3 0 1 1-6 0 3 3 0 0 1 6 0Zm6 3a2.25 2.25 0 1 1-4.5 0 2.25 2.25 0 0 1 " \
    "4.5 0Zm-13.5 0a2.25 2.25 0 1 1-4.5 0 2.25 2.25 0 0 1 4.5 0Z"

  ICON_ROCKET = "M15.59 14.37a6 6 0 0 1-5.84 7.38v-4.8m5.84-2.58a14.98 14.98 0 0 0 6.16-12.12A14.98 " \
    "14.98 0 0 0 9.631 8.41m5.96 5.96a14.926 14.926 0 0 1-5.841 2.58m-.119-8.54a6 6 0 0 0-7.381 5.84h4.8" \
    "m2.581-5.84a14.927 14.927 0 0 0-2.58 5.84m2.699 2.7c-.103.021-.207.041-.311.06a15.09 15.09 0 0 " \
    "1-2.448-2.448 14.9 14.9 0 0 1 .06-.312m-2.24 2.39a4.493 4.493 0 0 0-1.757 4.306 4.493 4.493 0 0 " \
    "0 4.306-1.758M16.5 9a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0Z"

  ICON_BELL = "M14.857 17.082a23.848 23.848 0 0 0 5.454-1.31A8.967 8.967 0 0 1 18 9.75V9A6 6 0 0 0 6 " \
    "9v.75a8.967 8.967 0 0 1-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 0 " \
    "1-5.714 0m5.714 0a3 3 0 1 1-5.714 0M3.124 7.5A8.969 8.969 0 0 1 5.292 3m13.416 0a8.969 8.969 " \
    "0 0 1 2.168 4.5"

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
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="#{WIDTH}" height="#{HEIGHT}" viewBox="0 0 #{WIDTH} #{HEIGHT}">
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
        <rect width="#{WIDTH}" height="200" fill="url(#headerGrad)"/>
        <rect y="194" width="#{WIDTH}" height="6" fill="url(#accentGrad)"/>

        <!-- Header: brand + event -->
        <text x="52" y="90" font-family="sans-serif" font-weight="900" font-size="58" fill="white" letter-spacing="-1">Western Sydney 10</text>
        <text x="1148" y="90" font-family="sans-serif" font-weight="900" font-size="58" fill="white" text-anchor="end" letter-spacing="-1">Event ##{escape s[:event_number]}</text>
        <text x="52" y="150" font-family="sans-serif" font-size="28" fill="rgba(255,255,255,0.88)">#{escape s[:date_str]}</text>
        <text x="1148" y="150" font-family="sans-serif" font-size="28" fill="rgba(255,255,255,0.88)" text-anchor="end">#{escape s[:location_name]}</text>

        <!-- Stat cards -->
        #{stat_card(x: 40,  value: s[:participant_count], label: "RUNNERS",        color: "#DB2955", bg: "#FDF4F7", icon: ICON_USER_GROUP)}
        #{stat_card(x: 430, value: s[:first_timer_count], label: "FIRST TIMERS",   color: "#DB2955", bg: "#FDF4F7", icon: ICON_ROCKET)}
        #{stat_card(x: 820, value: s[:pb_count],          label: "PERSONAL BESTS", color: "#B98389", bg: "#FBF7F7", icon: ICON_BELL)}

        <!-- Bottom panels -->
        <rect x="40"  y="432" width="530" height="162" rx="12" fill="#F8F9FA"/>
        <rect x="40"  y="432" width="530" height="5"   rx="12" fill="url(#accentGrad)"/>
        <rect x="630" y="432" width="530" height="162" rx="12" fill="#F8F9FA"/>
        <rect x="630" y="432" width="530" height="5"   rx="12" fill="#9DA39A"/>

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

  def stat_card(x:, value:, label:, color:, bg:, icon:)
    cx = x + 170
    y = 216
    <<~SVG
      <rect x="#{x}" y="#{y}" width="340" height="200" rx="12" fill="#{bg}"/>
      <rect x="#{x}" y="#{y}" width="340" height="5" rx="12" fill="#{color}"/>
      <circle cx="#{cx}" cy="#{y + 58}" r="28" fill="white" opacity="0.7"/>
      <svg x="#{cx - 18}" y="#{y + 40}" width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#{color}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
        <path d="#{icon}"/>
      </svg>
      <text x="#{cx}" y="#{y + 132}" font-family="sans-serif" font-weight="900" font-size="64" fill="#{color}" text-anchor="middle">#{value}</text>
      <text x="#{cx}" y="#{y + 178}" font-family="sans-serif" font-size="17" fill="#7E8287" text-anchor="middle" letter-spacing="2">#{label}</text>
    SVG
  end

  def records_section(s)
    base_x = 52
    label_y = 464
    svg = +""

    if s[:new_ws10_record]
      svg << "<text x=\"#{base_x}\" y=\"#{label_y}\" font-family=\"sans-serif\" font-size=\"15\" fill=\"#9DA39A\" letter-spacing=\"3\">RECORDS</text>\n"
      svg << "<text x=\"#{base_x}\" y=\"#{label_y + 36}\" font-family=\"sans-serif\" font-weight=\"bold\" font-size=\"22\" fill=\"#DB2955\">★  NEW WS10 RECORD</text>\n"
      svg << "<text x=\"#{base_x}\" y=\"#{label_y + 88}\" font-family=\"sans-serif\" font-weight=\"900\" font-size=\"52\" fill=\"#54494B\">#{escape s[:fastest_time_str]}</text>\n"
    elsif s[:new_course_record]
      svg << "<text x=\"#{base_x}\" y=\"#{label_y}\" font-family=\"sans-serif\" font-size=\"15\" fill=\"#9DA39A\" letter-spacing=\"3\">RECORDS</text>\n"
      svg << "<text x=\"#{base_x}\" y=\"#{label_y + 36}\" font-family=\"sans-serif\" font-weight=\"bold\" font-size=\"22\" fill=\"#DB2955\">★  NEW COURSE RECORD</text>\n"
      svg << "<text x=\"#{base_x}\" y=\"#{label_y + 88}\" font-family=\"sans-serif\" font-weight=\"900\" font-size=\"52\" fill=\"#54494B\">#{escape s[:fastest_time_str]}</text>\n"
    elsif s[:fastest_time_str]
      svg << "<text x=\"#{base_x}\" y=\"#{label_y}\" font-family=\"sans-serif\" font-size=\"15\" fill=\"#9DA39A\" letter-spacing=\"3\">FIRST FINISHER</text>\n"
      svg << "<text x=\"#{base_x}\" y=\"#{label_y + 88}\" font-family=\"sans-serif\" font-weight=\"900\" font-size=\"52\" fill=\"#54494B\">#{escape s[:fastest_time_str]}</text>\n"
    else
      svg << "<text x=\"#{base_x}\" y=\"#{label_y}\" font-family=\"sans-serif\" font-size=\"15\" fill=\"#9DA39A\" letter-spacing=\"3\">RECORDS</text>\n"
      svg << "<text x=\"#{base_x}\" y=\"#{label_y + 40}\" font-family=\"sans-serif\" font-size=\"22\" fill=\"#54494B\">First event here.</text>\n"
      svg << "<text x=\"#{base_x}\" y=\"#{label_y + 76}\" font-family=\"sans-serif\" font-size=\"22\" fill=\"#9DA39A\">Go set a benchmark!</text>\n"
    end

    svg
  end

  # Each unique (family, level) combination is a "stack". Duplicates peek out
  # from behind the front badge to give a sense of count without cluttering.
  BADGE_CARD_SIZE = 68
  BADGE_IMG_INSET = 3  # padding inside the card rect
  BADGE_PEEK_X    = 8  # how far each duplicate peeks to the right
  BADGE_PEEK_Y    = 3  # slight downward offset for depth
  BADGE_STACK_GAP = 16 # horizontal gap between different stacks

  def badges_section(s)
    base_x = 642
    label_y = 464
    badge_y = label_y + 14
    svg = +""
    svg << "<text x=\"#{base_x}\" y=\"#{label_y}\" font-family=\"sans-serif\" font-size=\"15\" fill=\"#9DA39A\" letter-spacing=\"3\">BADGES AWARDED</text>\n"

    stacks = s[:badge_stacks]
    if stacks.empty?
      svg << "<text x=\"#{base_x}\" y=\"#{label_y + 42}\" font-family=\"sans-serif\" font-size=\"22\" fill=\"#54494B\">Keep running —</text>\n"
      svg << "<text x=\"#{base_x}\" y=\"#{label_y + 74}\" font-family=\"sans-serif\" font-size=\"22\" fill=\"#9DA39A\">your badge is coming!</text>\n"
    else
      gx = base_x
      stacks.each do |stack|
        gx = render_badge_stack(svg, stack, gx, badge_y)
        gx += BADGE_STACK_GAP
      end
    end

    svg
  end

  # Renders a stack of badges at position (gx, gy), returns the x position after the stack.
  def render_badge_stack(svg, stack, gx, gy)
    family = stack[:family]
    level  = stack[:level]
    count  = stack[:count]
    color  = BADGE_COLORS[level]
    img_uri = badge_data_uri(family, level)
    img_size = BADGE_CARD_SIZE - BADGE_IMG_INSET * 2

    # Draw from back to front so the front badge ends up on top (SVG z-order)
    count.downto(1) do |i|
      dx = (i - 1) * BADGE_PEEK_X
      dy = (i - 1) * BADGE_PEEK_Y
      svg << "<rect x=\"#{gx + dx}\" y=\"#{gy + dy}\" width=\"#{BADGE_CARD_SIZE}\" height=\"#{BADGE_CARD_SIZE}\" rx=\"10\" fill=\"white\" stroke=\"#{color}\" stroke-width=\"2\"/>\n"
      svg << "<image href=\"#{img_uri}\" x=\"#{gx + dx + BADGE_IMG_INSET}\" y=\"#{gy + dy + BADGE_IMG_INSET}\" width=\"#{img_size}\" height=\"#{img_size}\"/>\n"
    end

    gx + BADGE_CARD_SIZE + (count - 1) * BADGE_PEEK_X
  end

  def badge_data_uri(family, level)
    png_name = "#{family}-#{level}"
    path = Rails.root.join("public/badges/#{png_name}.png")
    encoded = Base64.strict_encode64(File.binread(path))
    "data:image/png;base64,#{encoded}"
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
    badge_stacks = build_badge_stacks(badge_records)

    {
      event_number: @event.number,
      date_str: @event.date.strftime("%-d %B %Y"),
      location_name: @event.location.name,
      participant_count: participant_count,
      first_timer_count: first_timer_count,
      pb_count: pb_count,
      fastest_time_str: fastest_time_str,
      new_course_record: new_course_record,
      new_ws10_record: new_ws10_record,
      badge_count: badge_records.count,
      badge_stacks: badge_stacks
    }
  end

  # Groups badge records into stacks sorted by family (highest-level family first),
  # then within each family by level descending (gold before silver before bronze).
  def build_badge_stacks(badge_records)
    grouped = badge_records.group_by { |ub| [ ub.badge.badge_family, ub.badge.level ] }
    stacks = grouped.map do |(family, level), records|
      { family: family, level: level, level_order: BADGE_LEVEL_ORDER[level] || 0, count: records.size }
    end

    family_max_order = stacks.group_by { |s| s[:family] }
                             .transform_values { |ss| ss.map { |s| s[:level_order] }.max }

    stacks.sort_by { |s| [ -family_max_order[s[:family]], s[:family], -s[:level_order] ] }
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

  def escape(str)
    str.to_s
       .gsub("&", "&amp;")
       .gsub("<", "&lt;")
       .gsub(">", "&gt;")
       .gsub('"', "&quot;")
  end
end
