require "test_helper"

class BadgeEligibilityCheckerTest < ActiveSupport::TestCase
  def setup
    # Empty setup per project guidelines
  end

  # Centurion badge tests
  test "user with 10 results earns centurion badge" do
    user = users(:one)
    badge = badges(:centurion_bronze)
    location = locations(:bungarribee)

    10.times do |i|
      event = Event.create!(date: Date.today + i.days, location: location, number: i + 100, status: "finalised")
      Result.create!(user: user, event: event)
    end

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    assert checker.eligible_for?(badge)
  end

  test "user with 9 results does not earn centurion badge" do
    user = users(:one)
    user.results.destroy_all
    badge = badges(:centurion_bronze)
    location = locations(:bungarribee)

    9.times do |i|
      event = Event.create!(date: Date.today + i.days, location: location, number: i + 100, status: "finalised")
      Result.create!(user: user, event: event)
    end

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    assert_not checker.eligible_for?(badge)
  end

  # Traveller badge tests
  test "user who attended all locations earns traveller badge" do
    user = users(:one)
    badge = badges(:traveller_bronze)

    all_locations = [ locations(:bungarribee), locations(:nepean), locations(:parramatta) ]
    all_locations.each_with_index do |location, i|
      event = Event.create!(date: Date.today + i.days, location: location, number: i + 100, status: "finalised")
      Result.create!(user: user, event: event)
    end

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    assert checker.eligible_for?(badge)
  end

  test "user with one location does not earn traveller bronze badge" do
    user = users(:one)
    user.results.destroy_all
    badge = badges(:traveller_bronze)

    # Only attend one location (need all locations for bronze)
    event = Event.create!(date: Date.today, location: locations(:bungarribee), number: 100, status: "finalised")
    Result.create!(user: user, event: event)

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    assert_not checker.eligible_for?(badge)
  end

  # Consistent badge tests
  test "user with 3 consecutive events earns consistent badge" do
    user = users(:one)
    badge = badges(:consistent_bronze)

    event1 = Event.create!(date: Date.today, location: locations(:bungarribee), number: 100, status: "finalised")
    event2 = Event.create!(date: Date.today + 7.days, location: locations(:bungarribee), number: 101, status: "finalised")
    event3 = Event.create!(date: Date.today + 14.days, location: locations(:bungarribee), number: 102, status: "finalised")

    Result.create!(user: user, event: event1)
    Result.create!(user: user, event: event2)
    Result.create!(user: user, event: event3)

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    assert checker.eligible_for?(badge)
  end

  test "user with non-consecutive events does not earn consistent badge" do
    user = users(:one)
    badge = badges(:consistent_bronze)

    event1 = Event.create!(date: Date.today, location: locations(:bungarribee), number: 100, status: "finalised")
    event2 = Event.create!(date: Date.today + 7.days, location: locations(:bungarribee), number: 101, status: "finalised")
    event3 = Event.create!(date: Date.today + 14.days, location: locations(:bungarribee), number: 103, status: "finalised")

    Result.create!(user: user, event: event1)
    Result.create!(user: user, event: event2)
    Result.create!(user: user, event: event3)

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    assert_not checker.eligible_for?(badge)
  end

  # Simply the Best badge tests
  test "user with 1 personal best earns simply the best badge" do
    user = users(:one)
    user.results.destroy_all
    badge = badges(:simply_the_best_bronze)

    # First result is never a PB (first_timer?)
    # Second result IS a PB (first timed result)
    event1 = Event.create!(date: Date.today, location: locations(:bungarribee), number: 100, status: "finalised")
    Result.create!(user: user, event: event1, time: 2000)

    event2 = Event.create!(date: Date.today + 1.day, location: locations(:bungarribee), number: 101, status: "finalised")
    Result.create!(user: user, event: event2, time: 1990)

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    assert checker.eligible_for?(badge)
  end

  test "user with 0 personal bests does not earn simply the best badge" do
    user = users(:one)
    user.results.destroy_all
    badge = badges(:simply_the_best_bronze)

    # Just one result, which is first timer (not a PB)
    event1 = Event.create!(date: Date.today, location: locations(:bungarribee), number: 100, status: "finalised")
    Result.create!(user: user, event: event1, time: 2000)

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    assert_not checker.eligible_for?(badge)
  end

  # Heart of Gold badge tests
  test "user with 1 volunteer role earns heart of gold badge" do
    user = users(:one)
    badge = badges(:heart_of_gold_bronze)

    event = Event.create!(date: Date.today, location: locations(:bungarribee), number: 100, status: "finalised")
    Volunteer.create!(user: user, event: event, role: "Marshal")

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    assert checker.eligible_for?(badge)
  end

  test "user with 0 volunteer roles does not earn heart of gold badge" do
    user = users(:one)
    user.volunteers.destroy_all
    badge = badges(:heart_of_gold_bronze)

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    assert_not checker.eligible_for?(badge)
  end

  # check_and_award_all tests
  test "check_and_award_all awards eligible badges" do
    user = users(:one)
    user.results.destroy_all # Clear any existing fixture results

    # Set up data for centurion badge (10 results)
    created_events = []
    10.times do |i|
      event = Event.create!(date: Date.today + i.days, location: locations(:bungarribee), number: i + 100, status: "finalised")
      Result.create!(user: user, event: event)
      created_events << event
    end

    triggering_event = events(:one)
    checker = BadgeEligibilityChecker.new(user, event_id: triggering_event.id)
    newly_earned = checker.check_and_award_all

    assert_includes newly_earned.map(&:slug), "centurion-bronze"
    assert user.badges.exists?(slug: "centurion-bronze")

    # Verify event_id is set correctly to the 10th result's event (the qualifying event)
    user_badge = user.user_badges.joins(:badge).find_by(badges: { slug: "centurion-bronze" })
    qualifying_event = created_events[9] # 10th event (0-indexed)
    assert_equal qualifying_event.id, user_badge.event_id
  end

  test "check_and_award_all does not award already earned badges" do
    user = users(:one)
    user.results.destroy_all
    user.volunteers.destroy_all
    centurion_badge = badges(:centurion_bronze)
    traveller_badge = badges(:traveller_bronze)
    event = events(:one)

    # Already earned these badges
    UserBadge.create!(user: user, badge: centurion_badge, event: event)
    UserBadge.create!(user: user, badge: traveller_badge, event: event)

    # Still eligible for centurion and traveller, but not for other badges (use non-consecutive event numbers)
    10.times do |i|
      event = Event.create!(date: Date.today + i.days, location: locations(:bungarribee), number: (i * 10) + 100, status: "finalised")
      Result.create!(user: user, event: event)
    end

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)

    assert_no_difference "UserBadge.count" do
      newly_earned = checker.check_and_award_all
      assert_empty newly_earned
    end
  end

  test "check_and_award_all returns newly earned badges" do
    user = users(:one)

    # Set up for multiple badges
    10.times do |i|
      event = Event.create!(date: Date.today + i.days, location: locations(:bungarribee), number: i + 100, status: "finalised")
      Result.create!(user: user, event: event)
      Volunteer.create!(user: user, event: event, role: "Marshal")
    end

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    newly_earned = checker.check_and_award_all

    assert newly_earned.length > 0
    assert_includes newly_earned.map(&:slug), "centurion-bronze"
    assert_includes newly_earned.map(&:slug), "heart-of-gold-bronze"
  end

  test "silver badge replaces bronze badge" do
    user = users(:one)
    user.results.destroy_all
    user.volunteers.destroy_all
    centurion_bronze = badges(:centurion_bronze)
    centurion_silver = badges(:centurion_silver)

    # Earn bronze (10 results)
    10.times do |i|
      event = Event.create!(date: Date.today + i.days, location: locations(:bungarribee), number: i + 100, status: "finalised")
      Result.create!(user: user, event: event)
    end

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    assert user.badges.exists?(slug: "centurion-bronze")
    assert_not user.badges.exists?(slug: "centurion-silver")

    # Earn silver (20 results total)
    10.times do |i|
      event = Event.create!(date: Date.today + (i + 10).days, location: locations(:bungarribee), number: i + 110, status: "finalised")
      Result.create!(user: user, event: event)
    end

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    # Silver should replace bronze
    assert_not user.badges.exists?(slug: "centurion-bronze")
    assert user.badges.exists?(slug: "centurion-silver")
  end

  test "gold badge replaces silver badge" do
    user = users(:one)
    user.results.destroy_all
    user.volunteers.destroy_all

    # Earn bronze and silver
    20.times do |i|
      event = Event.create!(date: Date.today + i.days, location: locations(:bungarribee), number: i + 100, status: "finalised")
      Result.create!(user: user, event: event)
    end

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    assert user.badges.exists?(slug: "centurion-silver")

    # Earn gold (40 results total)
    20.times do |i|
      event = Event.create!(date: Date.today + (i + 20).days, location: locations(:bungarribee), number: i + 120, status: "finalised")
      Result.create!(user: user, event: event)
    end

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    # Gold should replace silver (and bronze should already be gone)
    assert_not user.badges.exists?(slug: "centurion-bronze")
    assert_not user.badges.exists?(slug: "centurion-silver")
    assert user.badges.exists?(slug: "centurion-gold")
  end

  test "repeatable badge starts new cycle after gold" do
    user = users(:one)
    user.results.destroy_all
    user.volunteers.destroy_all
    centurion_gold = badges(:centurion_gold)

    # Earn gold (40 results)
    40.times do |i|
      event = Event.create!(date: Date.today + i.days, location: locations(:bungarribee), number: i + 100, status: "finalised")
      Result.create!(user: user, event: event)
    end

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    assert user.badges.exists?(slug: "centurion-gold")
    assert_equal 1, user.badges.where(slug: "centurion-gold").count

    # If repeatable, earning bronze again should keep the gold
    if centurion_gold.repeatable?
      # Earn another 10 results to trigger second bronze
      10.times do |i|
        event = Event.create!(date: Date.today + (i + 40).days, location: locations(:bungarribee), number: i + 140, status: "finalised")
        Result.create!(user: user, event: event)
      end

      checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
      checker.check_and_award_all

      # Should have gold and bronze
      assert user.badges.exists?(slug: "centurion-gold")
      assert user.badges.exists?(slug: "centurion-bronze")
    end
  end

  test "all seasons badge uses Southern Hemisphere seasons" do
    user = users(:one)
    user.results.destroy_all
    user.volunteers.destroy_all
    all_seasons_badge = badges(:all_seasons)

    # Earn the badge first time (attend all 4 seasons using Southern Hemisphere dates)
    # Summer: Dec-Feb, Autumn: Mar-May, Winter: Jun-Aug, Spring: Sep-Nov
    event_summer = Event.create!(date: Date.new(2025, 1, 15), location: locations(:bungarribee), number: 100, status: "finalised")
    event_autumn = Event.create!(date: Date.new(2025, 4, 15), location: locations(:bungarribee), number: 101, status: "finalised")
    event_winter = Event.create!(date: Date.new(2025, 7, 15), location: locations(:bungarribee), number: 102, status: "finalised")
    event_spring = Event.create!(date: Date.new(2025, 10, 15), location: locations(:bungarribee), number: 103, status: "finalised")

    Result.create!(user: user, event: event_summer)
    Result.create!(user: user, event: event_autumn)
    Result.create!(user: user, event: event_winter)
    Result.create!(user: user, event: event_spring)

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    assert user.badges.exists?(slug: "all-seasons")
    assert_equal 1, user.user_badges.where(badge: all_seasons_badge).count
  end

  test "all seasons badge only counts one run per season per year" do
    user = users(:one)
    user.results.destroy_all
    user.volunteers.destroy_all
    all_seasons_badge = badges(:all_seasons)

    # Attend 3 events in summer (Dec-Feb), but only one should count
    event_summer_1 = Event.create!(date: Date.new(2025, 12, 15), location: locations(:bungarribee), number: 100, status: "finalised")
    event_summer_2 = Event.create!(date: Date.new(2026, 1, 15), location: locations(:bungarribee), number: 101, status: "finalised")
    event_summer_3 = Event.create!(date: Date.new(2026, 2, 15), location: locations(:bungarribee), number: 102, status: "finalised")

    # Also attend autumn, winter, and spring
    event_autumn = Event.create!(date: Date.new(2026, 4, 15), location: locations(:bungarribee), number: 103, status: "finalised")
    event_winter = Event.create!(date: Date.new(2026, 7, 15), location: locations(:bungarribee), number: 104, status: "finalised")
    event_spring = Event.create!(date: Date.new(2026, 10, 15), location: locations(:bungarribee), number: 105, status: "finalised")

    Result.create!(user: user, event: event_summer_1)
    Result.create!(user: user, event: event_summer_2)
    Result.create!(user: user, event: event_summer_3)
    Result.create!(user: user, event: event_autumn)
    Result.create!(user: user, event: event_winter)
    Result.create!(user: user, event: event_spring)

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    # Should earn the badge once (all 4 seasons covered in 2026)
    assert user.badges.exists?(slug: "all-seasons")
    assert_equal 1, user.user_badges.where(badge: all_seasons_badge).count
  end

  test "all seasons badge can only be earned once per calendar year" do
    user = users(:one)
    user.results.destroy_all
    user.volunteers.destroy_all
    all_seasons_badge = badges(:all_seasons)

    # Attend all 4 seasons in 2025
    event_summer = Event.create!(date: Date.new(2025, 1, 15), location: locations(:bungarribee), number: 100, status: "finalised")
    event_autumn = Event.create!(date: Date.new(2025, 4, 15), location: locations(:bungarribee), number: 101, status: "finalised")
    event_winter = Event.create!(date: Date.new(2025, 7, 15), location: locations(:bungarribee), number: 102, status: "finalised")
    event_spring = Event.create!(date: Date.new(2025, 10, 15), location: locations(:bungarribee), number: 103, status: "finalised")

    Result.create!(user: user, event: event_summer)
    Result.create!(user: user, event: event_autumn)
    Result.create!(user: user, event: event_winter)
    Result.create!(user: user, event: event_spring)

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    assert user.badges.exists?(slug: "all-seasons")
    assert_equal 1, user.user_badges.where(badge: all_seasons_badge).count

    # Attend more events in 2025 (all 4 seasons again)
    event_summer_2 = Event.create!(date: Date.new(2025, 2, 15), location: locations(:bungarribee), number: 104, status: "finalised")
    event_autumn_2 = Event.create!(date: Date.new(2025, 5, 15), location: locations(:bungarribee), number: 105, status: "finalised")
    event_winter_2 = Event.create!(date: Date.new(2025, 8, 15), location: locations(:bungarribee), number: 106, status: "finalised")
    event_spring_2 = Event.create!(date: Date.new(2025, 11, 15), location: locations(:bungarribee), number: 107, status: "finalised")

    Result.create!(user: user, event: event_summer_2)
    Result.create!(user: user, event: event_autumn_2)
    Result.create!(user: user, event: event_winter_2)
    Result.create!(user: user, event: event_spring_2)

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    newly_earned = checker.check_and_award_all

    # Should NOT earn the badge again in 2025
    assert_not_includes newly_earned.map(&:slug), "all-seasons"
    assert_equal 1, user.user_badges.where(badge: all_seasons_badge).count
  end

  test "all seasons badge can be earned in different calendar years" do
    user = users(:one)
    user.results.destroy_all
    user.volunteers.destroy_all
    all_seasons_badge = badges(:all_seasons)

    # Earn the badge in 2025
    event_summer = Event.create!(date: Date.new(2025, 1, 15), location: locations(:bungarribee), number: 100, status: "finalised")
    event_autumn = Event.create!(date: Date.new(2025, 4, 15), location: locations(:bungarribee), number: 101, status: "finalised")
    event_winter = Event.create!(date: Date.new(2025, 7, 15), location: locations(:bungarribee), number: 102, status: "finalised")
    event_spring = Event.create!(date: Date.new(2025, 10, 15), location: locations(:bungarribee), number: 103, status: "finalised")

    Result.create!(user: user, event: event_summer)
    Result.create!(user: user, event: event_autumn)
    Result.create!(user: user, event: event_winter)
    Result.create!(user: user, event: event_spring)

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    assert user.badges.exists?(slug: "all-seasons")
    assert_equal 1, user.user_badges.where(badge: all_seasons_badge).count

    # Earn the badge a second time in 2026 (attend all 4 seasons again)
    event_summer_2 = Event.create!(date: Date.new(2026, 1, 15), location: locations(:bungarribee), number: 104, status: "finalised")
    event_autumn_2 = Event.create!(date: Date.new(2026, 4, 15), location: locations(:bungarribee), number: 105, status: "finalised")
    event_winter_2 = Event.create!(date: Date.new(2026, 7, 15), location: locations(:bungarribee), number: 106, status: "finalised")
    event_spring_2 = Event.create!(date: Date.new(2026, 10, 15), location: locations(:bungarribee), number: 107, status: "finalised")

    Result.create!(user: user, event: event_summer_2)
    Result.create!(user: user, event: event_autumn_2)
    Result.create!(user: user, event: event_winter_2)
    Result.create!(user: user, event: event_spring_2)

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    newly_earned = checker.check_and_award_all

    # Should have earned the badge a second time in 2026
    assert_includes newly_earned.map(&:slug), "all-seasons"
    assert_equal 2, user.user_badges.where(badge: all_seasons_badge).count
  end

  test "all seasons badge links to event where all 4 seasons were first completed" do
    user = users(:one)
    user.results.destroy_all
    user.volunteers.destroy_all
    all_seasons_badge = badges(:all_seasons)

    # Attend events in Jan (summer), Feb (summer), March (autumn), July (winter), Oct (spring), Dec (summer)
    event1 = Event.create!(date: Date.new(2025, 1, 15), location: locations(:bungarribee), number: 201, status: "finalised")
    event2 = Event.create!(date: Date.new(2025, 2, 15), location: locations(:bungarribee), number: 202, status: "finalised")
    event3 = Event.create!(date: Date.new(2025, 3, 15), location: locations(:bungarribee), number: 203, status: "finalised")
    event7 = Event.create!(date: Date.new(2025, 7, 15), location: locations(:bungarribee), number: 207, status: "finalised")
    event10 = Event.create!(date: Date.new(2025, 10, 15), location: locations(:bungarribee), number: 210, status: "finalised")
    event12 = Event.create!(date: Date.new(2025, 12, 15), location: locations(:bungarribee), number: 212, status: "finalised")

    Result.create!(user: user, event: event1)
    Result.create!(user: user, event: event2)
    Result.create!(user: user, event: event3)
    Result.create!(user: user, event: event7)
    Result.create!(user: user, event: event10)
    Result.create!(user: user, event: event12)

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    # User completed all 4 seasons at event #210 (Oct - spring)
    # Jan/Feb = summer, March = autumn, July = winter, Oct = spring
    # Even though they attended Dec (summer again), the badge should link to Oct #210
    user_badge = user.user_badges.joins(:badge).find_by(badges: { slug: "all-seasons" })
    assert_equal event10.id, user_badge.event_id, "Badge should be linked to event #210 where all 4 seasons were first completed"
    assert_equal event10.date, user_badge.earned_at.to_date, "Badge earned_at should be the date of event #210"
  end

  # Monthly badge tests
  test "monthly badge awarded when user attends all 12 months" do
    user = users(:one)
    user.results.destroy_all
    user.volunteers.destroy_all
    monthly_badge = badges(:monthly)

    # Create events for all 12 months
    (1..12).each do |month|
      event = Event.create!(date: Date.new(2025, month, 15), location: locations(:bungarribee), number: 100 + month, status: "finalised")
      Result.create!(user: user, event: event)
    end

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    assert user.badges.exists?(slug: "monthly")
    assert_equal 1, user.user_badges.where(badge: monthly_badge).count
  end

  test "monthly badge not awarded when missing a month" do
    user = users(:one)
    user.results.destroy_all
    user.volunteers.destroy_all
    monthly_badge = badges(:monthly)

    # Create events for only 11 months (skip March)
    [ 1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12 ].each do |month|
      event = Event.create!(date: Date.new(2025, month, 15), location: locations(:bungarribee), number: 100 + month, status: "finalised")
      Result.create!(user: user, event: event)
    end

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    assert_not user.badges.exists?(slug: "monthly")
  end

  test "monthly badge counts runs across multiple years" do
    user = users(:one)
    user.results.destroy_all
    user.volunteers.destroy_all
    monthly_badge = badges(:monthly)

    # Create events across 2025 and 2026
    (1..6).each do |month|
      event = Event.create!(date: Date.new(2025, month, 15), location: locations(:bungarribee), number: 100 + month, status: "finalised")
      Result.create!(user: user, event: event)
    end

    (7..12).each do |month|
      event = Event.create!(date: Date.new(2026, month, 15), location: locations(:bungarribee), number: 100 + month, status: "finalised")
      Result.create!(user: user, event: event)
    end

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    assert user.badges.exists?(slug: "monthly")
    assert_equal 1, user.user_badges.where(badge: monthly_badge).count
  end

  test "second monthly badge awarded when all months have 2 runs" do
    user = users(:one)
    user.results.destroy_all
    user.volunteers.destroy_all
    monthly_badge = badges(:monthly)

    # Create 2 events for each of the 12 months
    (1..12).each do |month|
      event1 = Event.create!(date: Date.new(2025, month, 15), location: locations(:bungarribee), number: 100 + month, status: "finalised")
      event2 = Event.create!(date: Date.new(2026, month, 15), location: locations(:bungarribee), number: 200 + month, status: "finalised")
      Result.create!(user: user, event: event1)
      Result.create!(user: user, event: event2)
    end

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    assert user.badges.exists?(slug: "monthly")
    assert_equal 2, user.user_badges.where(badge: monthly_badge).count
  end

  test "second monthly badge not awarded when one month only has 1 run" do
    user = users(:one)
    user.results.destroy_all
    user.volunteers.destroy_all
    monthly_badge = badges(:monthly)

    # Create 2 events for 11 months, but only 1 for March
    (1..12).each do |month|
      event1 = Event.create!(date: Date.new(2025, month, 15), location: locations(:bungarribee), number: 100 + month, status: "finalised")
      Result.create!(user: user, event: event1)

      unless month == 3
        event2 = Event.create!(date: Date.new(2026, month, 15), location: locations(:bungarribee), number: 200 + month, status: "finalised")
        Result.create!(user: user, event: event2)
      end
    end

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    # Should earn first badge but not second
    assert user.badges.exists?(slug: "monthly")
    assert_equal 1, user.user_badges.where(badge: monthly_badge).count
  end

  test "monthly badge counts runs and volunteering together" do
    user = users(:one)
    user.results.destroy_all
    user.volunteers.destroy_all
    monthly_badge = badges(:monthly)

    # Create mix of runs and volunteering for all 12 months
    (1..6).each do |month|
      event = Event.create!(date: Date.new(2025, month, 15), location: locations(:bungarribee), number: 100 + month, status: "finalised")
      Result.create!(user: user, event: event)
    end

    (7..12).each do |month|
      event = Event.create!(date: Date.new(2025, month, 15), location: locations(:bungarribee), number: 100 + month, status: "finalised")
      Volunteer.create!(user: user, event: event, role: "Marshal")
    end

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    assert user.badges.exists?(slug: "monthly")
    assert_equal 1, user.user_badges.where(badge: monthly_badge).count
  end

  test "monthly badge early runs count towards later badge" do
    user = users(:one)
    user.results.destroy_all
    user.volunteers.destroy_all
    monthly_badge = badges(:monthly)

    # Run in Jan-Nov 2025 (missing December)
    (1..11).each do |month|
      event = Event.create!(date: Date.new(2025, month, 15), location: locations(:bungarribee), number: 100 + month, status: "finalised")
      Result.create!(user: user, event: event)
    end

    # Second run in Jan-Nov 2026 (still missing December)
    (1..11).each do |month|
      event = Event.create!(date: Date.new(2026, month, 15), location: locations(:bungarribee), number: 200 + month, status: "finalised")
      Result.create!(user: user, event: event)
    end

    # No badge yet
    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all
    assert_not user.badges.exists?(slug: "monthly")

    # Now run in December 2026 - should earn first badge
    event_dec_2026 = Event.create!(date: Date.new(2026, 12, 15), location: locations(:bungarribee), number: 300, status: "finalised")
    Result.create!(user: user, event: event_dec_2026)

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all
    assert_equal 1, user.user_badges.where(badge: monthly_badge).count

    # Now run in December 2027 - should earn second badge (using Jan-Nov 2025/2026 runs)
    event_dec_2027 = Event.create!(date: Date.new(2027, 12, 15), location: locations(:bungarribee), number: 400, status: "finalised")
    Result.create!(user: user, event: event_dec_2027)

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all
    assert_equal 2, user.user_badges.where(badge: monthly_badge).count
  end

  # Palindrome badge tests
  test "palindrome badge awarded for palindrome time" do
    user = users(:one)
    user.results.destroy_all
    palindrome_badge = badges(:palindrome)

    # Create result with palindrome time (52:25 = 3145 seconds)
    event = Event.create!(date: Date.new(2025, 1, 15), location: locations(:bungarribee), number: 100, status: "finalised")
    Result.create!(user: user, event: event, time: 3145)

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    assert user.badges.exists?(slug: "palindrome")
    assert_equal 1, user.user_badges.where(badge: palindrome_badge).count
  end

  test "palindrome badge not awarded for non-palindrome time" do
    user = users(:one)
    user.results.destroy_all

    # Create result with non-palindrome time
    event = Event.create!(date: Date.new(2025, 1, 15), location: locations(:bungarribee), number: 100, status: "finalised")
    Result.create!(user: user, event: event, time: 3000)

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    assert_not user.badges.exists?(slug: "palindrome")
  end

  test "palindrome badge awarded multiple times for multiple palindrome times" do
    user = users(:one)
    user.results.destroy_all
    palindrome_badge = badges(:palindrome)

    # Create first palindrome time (52:25 = 3145 seconds)
    event1 = Event.create!(date: Date.new(2025, 1, 15), location: locations(:bungarribee), number: 100, status: "finalised")
    Result.create!(user: user, event: event1, time: 3145)

    # Create second palindrome time (1:07:01 = 4021 seconds)
    event2 = Event.create!(date: Date.new(2025, 2, 15), location: locations(:bungarribee), number: 101, status: "finalised")
    Result.create!(user: user, event: event2, time: 4021)

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    assert user.badges.exists?(slug: "palindrome")
    assert_equal 2, user.user_badges.where(badge: palindrome_badge).count
  end

  test "palindrome badge only awarded once per palindrome time" do
    user = users(:one)
    user.results.destroy_all
    palindrome_badge = badges(:palindrome)

    # Create one palindrome time
    event = Event.create!(date: Date.new(2025, 1, 15), location: locations(:bungarribee), number: 100, status: "finalised")
    Result.create!(user: user, event: event, time: 3145)

    # Run checker twice
    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    checker.check_and_award_all

    checker = BadgeEligibilityChecker.new(user, event_id: events(:one).id)
    newly_earned = checker.check_and_award_all

    # Should have only one badge, not award it again
    assert_equal 1, user.user_badges.where(badge: palindrome_badge).count
    assert_not_includes newly_earned.map(&:slug), "palindrome"
  end
end
