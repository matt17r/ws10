require "test_helper"

class FinishPositionTest < ActiveSupport::TestCase
  test "allows multiple finish positions with nil position for same event" do
    event = events(:draft_event)
    user1 = users(:one)
    user2 = users(:two)

    fp1 = FinishPosition.create!(event: event, user: user1, position: nil)
    fp2 = FinishPosition.create!(event: event, user: user2, position: nil)

    assert fp1.persisted?
    assert fp2.persisted?
    assert_nil fp1.position
    assert_nil fp2.position
  end

  test "does not allow duplicate positions for same event" do
    event = events(:draft_event)
    user1 = users(:one)
    user2 = users(:two)

    FinishPosition.create!(event: event, user: user1, position: 1)
    fp2 = FinishPosition.new(event: event, user: user2, position: 1)

    assert_not fp2.valid?
    assert_includes fp2.errors[:position], "is already taken"
  end

  test "position must be greater than 0 if present" do
    event = events(:draft_event)
    user = users(:one)

    fp = FinishPosition.new(event: event, user: user, position: 0)

    assert_not fp.valid?
    assert_includes fp.errors[:position], "must be greater than 0"
  end

  test "position can be nil" do
    event = events(:draft_event)
    user = users(:one)

    fp = FinishPosition.create!(event: event, user: user, position: nil)

    assert fp.persisted?
    assert_nil fp.position
  end

  test "known_user? returns true when user is present" do
    event = events(:draft_event)
    user = users(:one)
    fp = FinishPosition.create!(event: event, user: user, position: 1)

    assert fp.known_user?
  end

  test "known_user? returns false when user is nil" do
    event = events(:draft_event)
    fp = FinishPosition.create!(event: event, user: nil, position: 1)

    assert_not fp.known_user?
  end

  test "user_name returns user name when user is present" do
    event = events(:draft_event)
    user = users(:one)
    fp = FinishPosition.create!(event: event, user: user, position: 1)

    assert_equal user.name_with_display_name, fp.user_name
  end

  test "user_name returns Unknown when user is nil" do
    event = events(:draft_event)
    fp = FinishPosition.create!(event: event, user: nil, position: 1)

    assert_equal "Unknown", fp.user_name
  end

  test "requires either user or position" do
    event = events(:draft_event)
    fp = FinishPosition.new(event: event, user: nil, position: nil)

    assert_not fp.valid?
    assert_includes fp.errors[:base], "Must have either a user or a position"
  end

  test "allows position without user" do
    event = events(:draft_event)
    fp = FinishPosition.create!(event: event, user: nil, position: 1)

    assert fp.persisted?
  end

  test "allows user without position" do
    event = events(:draft_event)
    user = users(:one)
    fp = FinishPosition.create!(event: event, user: user, position: nil)

    assert fp.persisted?
  end
end
