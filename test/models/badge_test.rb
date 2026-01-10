require "test_helper"

class BadgeTest < ActiveSupport::TestCase
  def valid_badge_attrs(overrides = {})
    {
      name: "Test Badge",
      slug: "test-badge",
      description: "A test badge",
      badge_family: "test",
      level: "bronze",
      level_order: 1,
      repeatable: false
    }.merge(overrides)
  end

  test "can create a valid badge" do
    badge = Badge.new(valid_badge_attrs)
    assert badge.valid?
  end

  test "requires name" do
    badge = Badge.new(valid_badge_attrs(name: nil))
    assert_not badge.valid?
    assert_includes badge.errors[:name], "can't be blank"
  end

  test "requires slug" do
    badge = Badge.new(valid_badge_attrs(slug: nil))
    assert_not badge.valid?
    assert_includes badge.errors[:slug], "can't be blank"
  end

  test "slug must be unique" do
    Badge.create!(valid_badge_attrs(slug: "unique-slug"))
    badge = Badge.new(valid_badge_attrs(slug: "unique-slug", badge_family: "different", level_order: 2))
    assert_not badge.valid?
    assert_includes badge.errors[:slug], "has already been taken"
  end

  test "slug must be lowercase alphanumeric with hyphens only" do
    valid_slugs = [ "test", "test-badge", "badge123", "test-badge-123" ]
    valid_slugs.each_with_index do |slug, index|
      badge = Badge.new(valid_badge_attrs(slug: slug, level_order: index + 1))
      assert badge.valid?, "#{slug} should be valid"
    end

    invalid_slugs = [ "Test", "test_badge", "test badge", "test.badge", "test/badge" ]
    invalid_slugs.each do |slug|
      badge = Badge.new(valid_badge_attrs(slug: slug))
      assert_not badge.valid?, "#{slug} should be invalid"
    end
  end

  test "database enforces NOT NULL on name" do
    badge = Badge.new(valid_badge_attrs(name: nil))
    assert_raises(ActiveRecord::NotNullViolation) { badge.save(validate: false) }
  end

  test "database enforces NOT NULL on slug" do
    badge = Badge.new(valid_badge_attrs(slug: nil))
    assert_raises(ActiveRecord::NotNullViolation) { badge.save(validate: false) }
  end

  test "database enforces unique slug" do
    Badge.create!(valid_badge_attrs(slug: "unique-slug"))
    badge = Badge.new(valid_badge_attrs(slug: "unique-slug", badge_family: "different", level_order: 2))
    assert_raises(ActiveRecord::RecordNotUnique) { badge.save(validate: false) }
  end

  test "destroying badge destroys associated user_badges" do
    user = users(:one)
    badge = Badge.create!(valid_badge_attrs(slug: "destroyable", level_order: 99))
    event = events(:one)
    user_badge = UserBadge.create!(user: user, badge: badge, event: event)

    assert_difference "UserBadge.count", -1 do
      badge.destroy
    end
  end

  test "accepts singular as a valid level" do
    badge = Badge.new(valid_badge_attrs(level: "singular"))
    assert badge.valid?
  end

  test "rejects invalid levels" do
    badge = Badge.new(valid_badge_attrs(level: "platinum"))
    assert_not badge.valid?
    assert_includes badge.errors[:level], "is not included in the list"
  end

  test "bronze? returns true for bronze badges" do
    badge = Badge.new(valid_badge_attrs(level: "bronze"))
    assert badge.bronze?
    assert_not badge.silver?
    assert_not badge.gold?
    assert_not badge.singular?
  end

  test "silver? returns true for silver badges" do
    badge = Badge.new(valid_badge_attrs(level: "silver"))
    assert badge.silver?
    assert_not badge.bronze?
    assert_not badge.gold?
    assert_not badge.singular?
  end

  test "gold? returns true for gold badges" do
    badge = Badge.new(valid_badge_attrs(level: "gold"))
    assert badge.gold?
    assert_not badge.bronze?
    assert_not badge.silver?
    assert_not badge.singular?
  end

  test "singular? returns true for singular badges" do
    badge = Badge.new(valid_badge_attrs(level: "singular"))
    assert badge.singular?
    assert_not badge.bronze?
    assert_not badge.silver?
    assert_not badge.gold?
  end
end
