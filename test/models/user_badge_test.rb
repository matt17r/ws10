require "test_helper"

class UserBadgeTest < ActiveSupport::TestCase
  test "can create a valid user_badge" do
    user = users(:one)
    badge = Badge.all.sample
    event = events(:one)
    user_badge = UserBadge.new(user: user, badge: badge, event: event)
    assert user_badge.valid?
  end

  test "automatically sets earned_at on creation" do
    user = users(:one)
    badge = Badge.all.sample
    event = events(:one)
    user_badge = UserBadge.create!(user: user, badge: badge, event: event)
    assert_not_nil user_badge.earned_at
    assert_in_delta Time.current, user_badge.earned_at, 1.second
  end

  test "does not override manually set earned_at" do
    user = users(:one)
    badge = Badge.all.sample
    event = events(:one)
    past_time = 2.days.ago
    user_badge = UserBadge.create!(user: user, badge: badge, event: event, earned_at: past_time)
    assert_in_delta past_time, user_badge.earned_at, 1.second
  end

  test "requires earned_at" do
    user = users(:one)
    badge = Badge.all.sample
    event = events(:one)
    user_badge = UserBadge.create!(user: user, badge: badge, event: event)
    user_badge.earned_at = nil
    assert_not user_badge.valid?
    assert_includes user_badge.errors[:earned_at], "can't be blank"
  end

  test "allows multiple user_badges for same user and badge" do
    user = users(:one)
    badge = Badge.all.sample
    event = events(:one)
    UserBadge.create!(user: user, badge: badge, event: event)
    second_badge = UserBadge.new(user: user, badge: badge, event: event)
    assert second_badge.valid?
  end

  test "database enforces NOT NULL on user_id" do
    badge = Badge.all.sample
    user_badge = UserBadge.new(badge: badge)
    assert_raises(ActiveRecord::NotNullViolation) { user_badge.save(validate: false) }
  end

  test "database enforces NOT NULL on badge_id" do
    user = users(:one)
    user_badge = UserBadge.new(user: user)
    assert_raises(ActiveRecord::NotNullViolation) { user_badge.save(validate: false) }
  end

  test "database enforces NOT NULL on earned_at" do
    user = users(:one)
    badge = Badge.all.sample
    user_badge = UserBadge.new(user: user, badge: badge, earned_at: nil)
    assert_raises(ActiveRecord::NotNullViolation) { user_badge.save(validate: false) }
  end

  test "recent scope returns badges earned within last hour" do
    user = users(:one)
    badge1, badge2 = Badge.all.sample(2)
    event = events(:one)
    recent_badge = UserBadge.create!(user: user, badge: badge1, event: event)
    old_badge = UserBadge.create!(user: user, badge: badge2, event: event, earned_at: 2.hours.ago)

    recent = UserBadge.recent
    assert_includes recent, recent_badge
    assert_not_includes recent, old_badge
  end

  test "for_event scope returns badges associated with specific event" do
    user = users(:one)
    event1 = events(:one)
    event2 = events(:two)
    badge1, badge2 = Badge.all.sample(2)

    event1_badge = UserBadge.create!(user: user, badge: badge1, event: event1)
    event2_badge = UserBadge.create!(user: user, badge: badge2, event: event2)

    event1_badges = UserBadge.for_event(event1)
    assert_includes event1_badges, event1_badge
    assert_not_includes event1_badges, event2_badge
  end

  test "display_name includes year for all-seasons badges" do
    user = users(:one)
    badge = badges(:all_seasons)
    event = events(:one)
    earned_date = Date.new(2025, 12, 15)
    user_badge = UserBadge.create!(user: user, badge: badge, event: event, earned_at: earned_date)

    assert_equal "All Seasons (2025)", user_badge.display_name
  end

  test "display_name shows just badge name for non all-seasons badges" do
    user = users(:one)
    badge = badges(:centurion_bronze)
    event = events(:one)
    user_badge = UserBadge.create!(user: user, badge: badge, event: event)

    assert_equal "Centurion (Bronze)", user_badge.display_name
  end

  test "requires event_id on creation" do
    user = users(:one)
    badge = Badge.all.sample
    user_badge = UserBadge.new(user: user, badge: badge)
    assert_not user_badge.valid?
    assert_includes user_badge.errors[:event_id], "can't be blank"
  end

  test "database enforces NOT NULL on event_id" do
    user = users(:one)
    badge = Badge.all.sample
    user_badge = UserBadge.new(user: user, badge: badge, event_id: nil)
    assert_raises(ActiveRecord::NotNullViolation) { user_badge.save(validate: false) }
  end

  test "database enforces foreign key constraint on event_id" do
    user = users(:one)
    badge = Badge.all.sample
    user_badge = UserBadge.new(user: user, badge: badge, event_id: 999999, earned_at: Time.current)
    assert_raises(ActiveRecord::InvalidForeignKey) { user_badge.save(validate: false) }
  end
end
