class BadgeEligibilityChecker
  def initialize(user, event_id: nil)
    @user = user
    @event_id = event_id
  end

  def check_and_award_all
    newly_earned = []

    Badge.select(:badge_family).distinct.pluck(:badge_family).each do |family|
      # For singular repeatable badges, calculate how many to award upfront
      family_badges = Badge.in_family(family).by_level_order
      first_badge = family_badges.first

      if first_badge.singular? && first_badge.repeatable?
        if family == "all-seasons"
          # Special handling for all-seasons to set earned_at per year
          result_dates = @user.results.joins(:event).pluck("events.date")
          volunteer_dates = @user.volunteers.joins(:event).pluck("events.date")
          all_dates = result_dates + volunteer_dates
          dates_by_year = all_dates.group_by(&:year)

          eligible_years = dates_by_year.keys.select do |year|
            year_dates = dates_by_year[year]
            seasons_in_year = year_dates.map { |date| month_to_season(date.month) }.uniq
            seasons_in_year.count == 4
          end

          earned_years = @user.user_badges.joins(:badge)
            .where(badges: { badge_family: "all-seasons" })
            .pluck(:earned_at)
            .map(&:year)

          unaward_years = eligible_years - earned_years

          unaward_years.each do |year|
            qualifying_event_id = qualifying_event_for_all_seasons(year)
            qualifying_event = Event.find(qualifying_event_id)
            @user.user_badges.create!(badge: first_badge, earned_at: qualifying_event.date, event_id: qualifying_event_id)
            newly_earned << first_badge
          end
        else
          # For other singular repeatable badges (monthly, palindrome, perfect-10)
          total_eligible = count_eligible_for_family(family)
          already_earned = @user.user_badges.joins(:badge)
            .where(badges: { badge_family: family })
            .count

          badges_to_award = total_eligible - already_earned
          badges_to_award.times do |i|
            nth_instance = already_earned + i + 1
            qualifying_event_id = case family
            when "monthly"
              qualifying_event_for_monthly(nth_instance)
            when "palindrome"
              qualifying_event_for_palindrome(nth_instance)
            when "perfect-10"
              qualifying_event_for_perfect_10
            end
            @user.user_badges.create!(badge: first_badge, event_id: qualifying_event_id)
            newly_earned << first_badge
          end
        end
      else
        # For non-singular or non-repeatable badges, use the loop with progression
        loop do
          badge = check_family_eligibility(family)
          break unless badge

          # Remove any lower-level badges from the same family
          @user.user_badges.joins(:badge)
            .where(badges: { badge_family: family })
            .where("badges.level_order < ?", badge.level_order)
            .destroy_all

          qualifying_event_id = case badge.badge_family
          when "centurion"
            qualifying_event_for_centurion(badge)
          when "traveller"
            qualifying_event_for_traveller(badge)
          when "consistent"
            qualifying_event_for_consistent(badge)
          when "simply-the-best"
            qualifying_event_for_simply_the_best(badge)
          when "heart-of-gold"
            qualifying_event_for_heart_of_gold(badge)
          when "founding-member"
            qualifying_event_for_founding_member
          else
            fallback_event_id
          end

          @user.user_badges.create!(badge: badge, event_id: qualifying_event_id)
          newly_earned << badge

          # Reload association to ensure fresh data for next iteration
          @user.user_badges.reload

          # For singular non-repeatable badges, there's no progression, so break after awarding
          break if badge.singular? && !badge.repeatable?
        end
      end
    end

    newly_earned
  end

  def check_family_eligibility(family)
    family_badges = Badge.in_family(family).by_level_order

    earned_badges = @user.user_badges.joins(:badge)
      .where(badges: { badge_family: family })
      .order(:earned_at, :id)

    if earned_badges.empty?
      target_level = 1
    else
      last_earned = earned_badges.last.badge
      if last_earned.gold? || last_earned.singular?
        if last_earned.repeatable?
          target_level = 1
        else
          return nil
        end
      else
        target_level = last_earned.level_order + 1
      end
    end

    target_badge = family_badges.find_by(level_order: target_level)
    return nil unless target_badge

    eligible_for?(target_badge) ? target_badge : nil
  end

  def eligible_for?(badge)
    case badge.badge_family
    when "centurion"
      eligible_for_centurion?(badge)
    when "traveller"
      eligible_for_traveller?(badge)
    when "consistent"
      eligible_for_consistent?(badge)
    when "simply-the-best"
      eligible_for_simply_the_best?(badge)
    when "heart-of-gold"
      eligible_for_heart_of_gold?(badge)
    when "founding-member"
      eligible_for_founding_member?(badge)
    when "monthly"
      eligible_for_monthly?(badge)
    when "all-seasons"
      eligible_for_all_seasons?(badge)
    when "palindrome"
      eligible_for_palindrome?(badge)
    when "perfect-10"
      eligible_for_perfect_10?(badge)
    else
      false
    end
  end

  private

  def count_eligible_for_family(family)
    case family
    when "monthly"
      result_months = @user.results.joins(:event).pluck("events.date").map(&:month)
      volunteer_months = @user.volunteers.joins(:event).pluck("events.date").map(&:month)
      all_months = result_months + volunteer_months
      month_counts = all_months.group_by(&:itself).transform_values(&:count)
      counts_for_all_months = (1..12).map { |month| month_counts[month] || 0 }
      counts_for_all_months.min
    when "all-seasons"
      result_dates = @user.results.joins(:event).pluck("events.date")
      volunteer_dates = @user.volunteers.joins(:event).pluck("events.date")
      all_dates = result_dates + volunteer_dates
      dates_by_year = all_dates.group_by(&:year)
      eligible_years = dates_by_year.keys.select do |year|
        year_dates = dates_by_year[year]
        seasons_in_year = year_dates.map { |date| month_to_season(date.month) }.uniq
        seasons_in_year.count == 4
      end
      eligible_years.count
    when "palindrome"
      @user.results.where.not(time: nil).count { |result| palindrome_time?(result.time) }
    when "perfect-10"
      positions = @user.finish_positions.where.not(position: nil).pluck(:position)
      last_digits = positions.map { |pos| pos % 10 }.uniq.sort
      last_digits == (0..9).to_a ? 1 : 0
    else
      0
    end
  end

  def eligible_for_centurion?(badge)
    count = @user.results.count
    completed_cycles = @user.user_badges.joins(:badge)
      .where(badges: { badge_family: "centurion", level: "gold" })
      .count

    base_threshold = case badge.level
    when "bronze" then 10
    when "silver" then 20
    when "gold" then 40
    end

    threshold = (completed_cycles * 40) + base_threshold
    count >= threshold
  end

  def eligible_for_traveller?(badge)
    result_locations = @user.results.joins(:event).pluck("events.location_id")
    volunteer_locations = @user.volunteers.joins(:event).pluck("events.location_id")
    all_locations = (result_locations + volunteer_locations)

    total_distinct_locations = Event.select(:location_id).distinct.count
    location_counts = all_locations.group_by(&:itself).transform_values(&:count)

    completed_cycles = @user.user_badges.joins(:badge)
      .where(badges: { badge_family: "traveller", level: "gold" })
      .count

    base_requirement = case badge.level
    when "bronze" then 1
    when "silver" then 2
    when "gold" then 4
    end

    required_count = (completed_cycles * 4) + base_requirement

    location_counts.all? { |_, count| count >= required_count } &&
      location_counts.keys.count >= total_distinct_locations &&
      total_distinct_locations >= 1
  end

  def eligible_for_consistent?(badge)
    result_event_numbers = @user.results.joins(:event).pluck("events.number")
    volunteer_event_numbers = @user.volunteers.joins(:event).pluck("events.number")
    event_numbers = (result_event_numbers + volunteer_event_numbers).uniq.sort

    completed_cycles = @user.user_badges.joins(:badge)
      .where(badges: { badge_family: "consistent", level: "gold" })
      .count

    base_requirement = case badge.level
    when "bronze" then 3
    when "silver" then 5
    when "gold" then 8
    end

    required_consecutive = (completed_cycles * 8) + base_requirement

    return false if event_numbers.length < required_consecutive

    event_numbers.each_cons(required_consecutive) do |sequence|
      return true if sequence.each_cons(2).all? { |a, b| b == a + 1 }
    end

    false
  end

  def eligible_for_simply_the_best?(badge)
    pb_count = @user.results.where.not(time: nil).count { |result| result.pb? }

    completed_cycles = @user.user_badges.joins(:badge)
      .where(badges: { badge_family: "simply-the-best", level: "gold" })
      .count

    base_requirement = case badge.level
    when "bronze" then 1
    when "silver" then 3
    when "gold" then 6
    end

    threshold = (completed_cycles * 6) + base_requirement
    pb_count >= threshold
  end


  def eligible_for_heart_of_gold?(badge)
    count = @user.volunteers.count

    completed_cycles = @user.user_badges.joins(:badge)
      .where(badges: { badge_family: "heart-of-gold", level: "gold" })
      .count

    base_requirement = case badge.level
    when "bronze" then 1
    when "silver" then 3
    when "gold" then 6
    end

    threshold = (completed_cycles * 6) + base_requirement
    count >= threshold
  end

  def eligible_for_founding_member?(badge)
    first_event = Event.order(:number).first
    return false unless first_event

    result_event_numbers = @user.results.joins(:event).pluck("events.number")
    volunteer_event_numbers = @user.volunteers.joins(:event).pluck("events.number")

    (result_event_numbers + volunteer_event_numbers).include?(first_event.number)
  end

  def eligible_for_monthly?(badge)
    # Not used for singular repeatable badges (handled in count_eligible_for_family)
    # Kept for consistency
    count_eligible_for_family("monthly") > 0
  end

  def eligible_for_all_seasons?(badge)
    # Not used for singular repeatable badges (handled in count_eligible_for_family)
    # But we need to track which year to set for earned_at
    result_dates = @user.results.joins(:event).pluck("events.date")
    volunteer_dates = @user.volunteers.joins(:event).pluck("events.date")
    all_dates = result_dates + volunteer_dates

    dates_by_year = all_dates.group_by(&:year)
    eligible_years = dates_by_year.keys.select do |year|
      year_dates = dates_by_year[year]
      seasons_in_year = year_dates.map { |date| month_to_season(date.month) }.uniq
      seasons_in_year.count == 4
    end

    return false if eligible_years.empty?

    earned_years = @user.user_badges.joins(:badge)
      .where(badges: { badge_family: "all-seasons" })
      .pluck(:earned_at)
      .map(&:year)

    unaward_years = eligible_years - earned_years
    return false if unaward_years.empty?

    @_all_seasons_awarded_year = unaward_years.max
    true
  end

  def eligible_for_palindrome?(badge)
    # Not used for singular repeatable badges (handled in count_eligible_for_family)
    # Kept for consistency
    count_eligible_for_family("palindrome") > 0
  end

  def eligible_for_perfect_10?(badge)
    # Not used for singular repeatable badges (handled in count_eligible_for_family)
    # Kept for consistency
    count_eligible_for_family("perfect-10") > 0
  end

  def month_to_season(month)
    case month
    when 12, 1, 2 then :summer
    when 3, 4, 5 then :autumn
    when 6, 7, 8 then :winter
    when 9, 10, 11 then :spring
    end
  end

  def palindrome_time?(time_in_seconds)
    hours = time_in_seconds / 3600
    minutes = (time_in_seconds % 3600) / 60
    seconds = time_in_seconds % 60

    if hours > 0
      time_string = format("%d%02d%02d", hours, minutes, seconds)
    else
      time_string = format("%02d%02d", minutes, seconds)
    end

    digits_only = time_string.chars
    digits_only == digits_only.reverse
  end

  def qualifying_event_for_centurion(badge)
    completed_cycles = @user.user_badges.joins(:badge)
      .where(badges: { badge_family: "centurion", level: "gold" })
      .count

    threshold = case badge.level
    when "bronze" then 10
    when "silver" then 20
    when "gold" then 40
    end

    threshold += (completed_cycles * 40)

    result = @user.results.joins(:event).order("events.number").offset(threshold - 1).first
    result&.event_id || fallback_event_id
  end

  def qualifying_event_for_traveller(badge)
    completed_cycles = @user.user_badges.joins(:badge)
      .where(badges: { badge_family: "traveller", level: "gold" })
      .count

    required_count = case badge.level
    when "bronze" then 1
    when "silver" then 2
    when "gold" then 4
    end

    required_count += (completed_cycles * 4)
    total_locations = Event.select(:location_id).distinct.count

    all_participation = @user.results.joins(:event).select("events.*").to_a +
                        @user.volunteers.joins(:event).select("events.*").to_a
    events = all_participation.map(&:itself).uniq.sort_by(&:number)

    location_counts = Hash.new(0)

    events.each do |event|
      location_counts[event.location_id] += 1

      if location_counts.keys.count >= total_locations &&
         location_counts.values.all? { |count| count >= required_count }
        return event.id
      end
    end

    fallback_event_id
  end

  def qualifying_event_for_consistent(badge)
    completed_cycles = @user.user_badges.joins(:badge)
      .where(badges: { badge_family: "consistent", level: "gold" })
      .count

    required_consecutive = case badge.level
    when "bronze" then 3
    when "silver" then 5
    when "gold" then 8
    end

    required_consecutive += (completed_cycles * 8)

    result_event_numbers = @user.results.joins(:event).pluck("events.number")
    volunteer_event_numbers = @user.volunteers.joins(:event).pluck("events.number")
    event_numbers = (result_event_numbers + volunteer_event_numbers).uniq.sort

    event_numbers.each_cons(required_consecutive) do |sequence|
      if sequence.each_cons(2).all? { |a, b| b == a + 1 }
        last_event_number = sequence.last
        event = Event.find_by(number: last_event_number)
        return event.id if event
      end
    end

    fallback_event_id
  end

  def qualifying_event_for_simply_the_best(badge)
    completed_cycles = @user.user_badges.joins(:badge)
      .where(badges: { badge_family: "simply-the-best", level: "gold" })
      .count

    threshold = case badge.level
    when "bronze" then 1
    when "silver" then 3
    when "gold" then 6
    end

    threshold += (completed_cycles * 6)

    pb_count = 0
    @user.results.where.not(time: nil).joins(:event).order("events.number").each do |result|
      if result.pb?
        pb_count += 1
        return result.event_id if pb_count == threshold
      end
    end

    fallback_event_id
  end

  def qualifying_event_for_heart_of_gold(badge)
    completed_cycles = @user.user_badges.joins(:badge)
      .where(badges: { badge_family: "heart-of-gold", level: "gold" })
      .count

    threshold = case badge.level
    when "bronze" then 1
    when "silver" then 3
    when "gold" then 6
    end

    threshold += (completed_cycles * 6)

    volunteer = @user.volunteers.joins(:event).order("events.date", "events.number").offset(threshold - 1).first
    volunteer&.event_id || fallback_event_id
  end

  def qualifying_event_for_founding_member
    first_event = Event.order(:number).first
    first_event&.id || fallback_event_id
  end

  def qualifying_event_for_monthly(nth_instance)
    events_with_results = @user.results.joins(:event).pluck("events.id", "events.date", "events.number")
    events_with_volunteers = @user.volunteers.joins(:event).pluck("events.id", "events.date", "events.number")

    all_events = (events_with_results + events_with_volunteers)
      .uniq
      .sort_by { |_id, date, number| [ date, number ] }

    month_counts = Hash.new(0)

    all_events.each do |event_id, date, _number|
      month = date.month
      month_counts[month] += 1

      current_min = (1..12).map { |m| month_counts[m] }.min

      return event_id if current_min == nth_instance
    end

    fallback_event_id
  end

  def qualifying_event_for_all_seasons(year)
    result_events = @user.results.joins(:event).pluck("events.date", "events.number", "events.id")
    volunteer_events = @user.volunteers.joins(:event).pluck("events.date", "events.number", "events.id")
    all_events = result_events + volunteer_events

    year_events = all_events
      .select { |date, _number, _id| date.year == year }
      .sort_by { |date, number, _id| [ date, number ] }

    seen_seasons = Set.new

    year_events.each do |date, _number, event_id|
      season = month_to_season(date.month)
      seen_seasons.add(season)

      return event_id if seen_seasons.size == 4
    end

    fallback_event_id
  end

  def qualifying_event_for_palindrome(nth_instance)
    palindrome_results = @user.results.where.not(time: nil)
      .joins(:event)
      .order("events.number")
      .select { |result| palindrome_time?(result.time) }

    result = palindrome_results[nth_instance - 1]
    result&.event_id || fallback_event_id
  end

  def qualifying_event_for_perfect_10
    positions_with_events = @user.finish_positions
      .where.not(position: nil)
      .joins(:event)
      .order("events.date", "events.number")
      .pluck(:position, "events.id")

    seen_digits = Set.new

    positions_with_events.each do |position, event_id|
      last_digit = position % 10
      seen_digits.add(last_digit)

      return event_id if seen_digits.size == 10
    end

    fallback_event_id
  end

  def fallback_event_id
    @event_id || Event.order(date: :desc).first&.id
  end
end
