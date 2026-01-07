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

  test "token_prefix_for_position generates 4 character hex prefix" do
    prefix = FinishPosition.token_prefix_for_position(1)
    assert_equal 4, prefix.length
    assert_match /^[a-f0-9]{4}$/, prefix
  end

  test "token_prefix_for_position is deterministic" do
    prefix1 = FinishPosition.token_prefix_for_position(1)
    prefix2 = FinishPosition.token_prefix_for_position(1)
    assert_equal prefix1, prefix2
  end

  test "token_prefix_for_position varies by position" do
    prefix1 = FinishPosition.token_prefix_for_position(1)
    prefix2 = FinishPosition.token_prefix_for_position(2)
    assert_not_equal prefix1, prefix2
  end

  test "valid_token? returns true for correct prefix" do
    prefix = FinishPosition.token_prefix_for_position(42)
    assert FinishPosition.valid_token?(prefix, 42)
  end

  test "valid_token? returns false for incorrect prefix" do
    assert_not FinishPosition.valid_token?("abc", 1)
  end

  test "token_path_for_position generates correct format" do
    path = FinishPosition.token_path_for_position(1)
    assert_match /^[a-f0-9]{4}\/001$/, path
  end

  test "token_path_for_position formats position with leading zeros" do
    path = FinishPosition.token_path_for_position(5)
    assert_match /\/005$/, path

    path = FinishPosition.token_path_for_position(42)
    assert_match /\/042$/, path

    path = FinishPosition.token_path_for_position(123)
    assert_match /\/123$/, path
  end
end
