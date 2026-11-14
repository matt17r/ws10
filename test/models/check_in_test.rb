require "test_helper"

class CheckInTest < ActiveSupport::TestCase
  test "creates valid check-in with required fields" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    user = users(:one)

    check_in = CheckIn.create!(
      user: user,
      event: event,
      checked_in_at: Time.current
    )

    assert check_in.persisted?
    assert_equal user, check_in.user
    assert_equal event, check_in.event
  end

  test "requires user" do
    check_in = CheckIn.new(event: events(:draft_event), checked_in_at: Time.current)
    assert_not check_in.valid?
    assert_includes check_in.errors[:user], "must exist"
  end

  test "requires event" do
    check_in = CheckIn.new(user: users(:one), checked_in_at: Time.current)
    assert_not check_in.valid?
    assert_includes check_in.errors[:event], "must exist"
  end

  test "requires checked_in_at" do
    check_in = CheckIn.new(user: users(:one), event: events(:draft_event))
    assert_not check_in.valid?
    assert_includes check_in.errors[:checked_in_at], "can't be blank"
  end

  test "prevents duplicate check-in for same user and event" do
    event = events(:draft_event)
    user = users(:one)

    CheckIn.create!(user: user, event: event, checked_in_at: Time.current)
    duplicate = CheckIn.new(user: user, event: event, checked_in_at: Time.current)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user], "already checked in to this event"
  end

  test "allows same user to check in to different events" do
    user = users(:one)
    event1 = events(:one)
    event2 = events(:two)

    CheckIn.create!(user: user, event: event1, checked_in_at: Time.current)
    check_in2 = CheckIn.create!(user: user, event: event2, checked_in_at: Time.current)

    assert check_in2.persisted?
  end

  test "allows different users to check in to same event" do
    event = events(:draft_event)
    user1 = users(:one)
    user2 = users(:two)

    CheckIn.create!(user: user1, event: event, checked_in_at: Time.current)
    check_in2 = CheckIn.create!(user: user2, event: event, checked_in_at: Time.current)

    assert check_in2.persisted?
  end

  test "token_for_event generates 8 character hex token" do
    token = CheckIn.token_for_event(1)
    assert_equal 8, token.length
    assert_match /^[a-f0-9]{8}$/, token
  end

  test "token_for_event is deterministic" do
    token1 = CheckIn.token_for_event(1)
    token2 = CheckIn.token_for_event(1)
    assert_equal token1, token2
  end

  test "token_for_event varies by event number" do
    token1 = CheckIn.token_for_event(1)
    token2 = CheckIn.token_for_event(2)
    assert_not_equal token1, token2
  end

  test "token_for_event differs from finish position tokens" do
    check_in_token = CheckIn.token_for_event(1)
    finish_position_token = FinishPosition.token_prefix_for_position(1)
    assert_not_equal check_in_token, finish_position_token
  end

  test "valid_token? returns true for correct token" do
    token = CheckIn.token_for_event(42)
    assert CheckIn.valid_token?(token, 42)
  end

  test "valid_token? returns false for incorrect token" do
    assert_not CheckIn.valid_token?("abcdefgh", 1)
  end

  test "valid_token? returns false for wrong event number" do
    token = CheckIn.token_for_event(1)
    assert_not CheckIn.valid_token?(token, 2)
  end

  test "token_path_for_event generates correct format" do
    path = CheckIn.token_path_for_event(1)
    assert_match /^[a-f0-9]{8}\/checkin$/, path
  end

  test "database enforces unique constraint on user_id and event_id" do
    event = events(:draft_event)
    user = users(:one)

    CheckIn.create!(user: user, event: event, checked_in_at: Time.current)

    assert_raises(ActiveRecord::RecordNotUnique) do
      CheckIn.new(user: user, event: event, checked_in_at: Time.current).save(validate: false)
    end
  end

  test "database enforces not null on user_id" do
    check_in = CheckIn.new(user_id: nil, event: events(:draft_event), checked_in_at: Time.current)
    assert_raises(ActiveRecord::NotNullViolation) do
      check_in.save(validate: false)
    end
  end

  test "database enforces not null on event_id" do
    check_in = CheckIn.new(user: users(:one), event_id: nil, checked_in_at: Time.current)
    assert_raises(ActiveRecord::NotNullViolation) do
      check_in.save(validate: false)
    end
  end

  test "database enforces not null on checked_in_at" do
    check_in = CheckIn.new(user: users(:one), event: events(:draft_event), checked_in_at: nil)
    assert_raises(ActiveRecord::NotNullViolation) do
      check_in.save(validate: false)
    end
  end
end
