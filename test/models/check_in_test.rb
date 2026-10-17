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

  test "status defaults to approved" do
    check_in = CheckIn.create!(user: users(:one), event: events(:draft_event), checked_in_at: Time.current)

    assert check_in.approved?
  end

  test "status can be pending" do
    check_in = CheckIn.create!(user: users(:one), event: events(:draft_event), checked_in_at: Time.current, status: "pending")

    assert check_in.pending?
  end

  test "rejects unknown status" do
    check_in = CheckIn.new(user: users(:one), event: events(:draft_event), checked_in_at: Time.current, status: "maybe")

    assert_not check_in.valid?
    assert_includes check_in.errors[:status], "is not included in the list"
  end

  test "database enforces valid status" do
    check_in = CheckIn.create!(user: users(:one), event: events(:draft_event), checked_in_at: Time.current)

    assert_raises(ActiveRecord::StatementInvalid) do
      check_in.update_column(:status, "maybe")
    end
  end

  test "database enforces not null on status" do
    check_in = CheckIn.create!(user: users(:one), event: events(:draft_event), checked_in_at: Time.current)

    assert_raises(ActiveRecord::NotNullViolation) do
      check_in.update_column(:status, nil)
    end
  end

  test "check_in! creates an approved check-in and a participant result" do
    event = events(:draft_event)
    user = users(:three)

    check_in = CheckIn.check_in!(event: event, user: user)

    assert check_in.approved?
    assert_equal user, check_in.user
    result = event.results.find_by!(user: user)
    assert_nil result.time
  end

  test "check_in! increments the user's results count" do
    user = users(:three)

    assert_difference -> { user.reload.results_count }, 1 do
      CheckIn.check_in!(event: events(:draft_event), user: user)
    end
  end

  test "check_in! keeps the time on an existing result" do
    event = events(:draft_event)
    user = users(:three)
    event.results.create!(user: user, time: 3000)

    assert_no_difference "Result.count" do
      CheckIn.check_in!(event: event, user: user)
    end

    assert_equal 3000, event.results.find_by!(user: user).time
  end

  test "check_in! twice raises and leaves the first check-in in place" do
    event = events(:draft_event)
    user = users(:three)
    CheckIn.check_in!(event: event, user: user)

    assert_no_difference [ "CheckIn.count", "Result.count" ] do
      assert_raises(ActiveRecord::RecordInvalid) do
        CheckIn.check_in!(event: event, user: user)
      end
    end
  end

  test "check_in! as pending does not create a result" do
    check_in = nil

    assert_no_difference "Result.count" do
      check_in = CheckIn.check_in!(event: events(:draft_event), user: users(:three), status: "pending")
    end

    assert check_in.pending?
  end

  test "record_time! on an approved check-in sets the result's time" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.check_in!(event: event, user: user)

    check_in.record_time!("52:25")

    assert_equal 52 * 60 + 25, event.results.find_by!(user: user).time
  end

  test "record_time! can change a time already recorded" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.check_in!(event: event, user: user)
    check_in.record_time!("52:25")

    check_in.record_time!("51:25")

    assert_equal 51 * 60 + 25, event.results.find_by!(user: user).time
  end

  test "record_time! with a blank time makes the runner a participant again" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.check_in!(event: event, user: user)
    check_in.record_time!("52:25")

    check_in.record_time!("")

    assert_nil event.results.find_by!(user: user).time
  end

  test "record_time! with an invalid time raises and leaves the result unchanged" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.check_in!(event: event, user: user)
    check_in.record_time!("52:25")

    assert_raises(ActiveRecord::RecordInvalid) do
      check_in.record_time!("nonsense")
    end

    assert_equal 52 * 60 + 25, event.results.find_by!(user: user).time
  end

  test "record_time! on a pending check-in saves the submitted time without creating a result" do
    check_in = CheckIn.check_in!(event: events(:draft_event), user: users(:three), status: "pending")

    assert_no_difference "Result.count" do
      check_in.record_time!("52:25")
    end

    assert_equal 52 * 60 + 25, check_in.reload.submitted_time
  end

  test "record_time! on a pending check-in with an invalid time leaves the submitted time unchanged" do
    check_in = CheckIn.check_in!(event: events(:draft_event), user: users(:three), status: "pending")
    check_in.record_time!("52:25")

    assert_raises(ActiveRecord::RecordInvalid) do
      check_in.record_time!("nonsense")
    end

    assert_equal 52 * 60 + 25, check_in.reload.submitted_time
  end

  test "recorded_time_string shows the result's time for an approved check-in" do
    check_in = CheckIn.check_in!(event: events(:draft_event), user: users(:three))
    check_in.record_time!("52:25")

    assert_equal "52:25", check_in.recorded_time_string
  end

  test "recorded_time_string shows the submitted time for a pending check-in" do
    check_in = CheckIn.check_in!(event: events(:draft_event), user: users(:three), status: "pending")
    check_in.record_time!("52:25")

    assert_equal "52:25", check_in.recorded_time_string
  end

  test "recorded_time_string is nil when no time has been recorded" do
    check_in = CheckIn.check_in!(event: events(:draft_event), user: users(:three))

    assert_nil check_in.recorded_time_string
  end

  test "approve! marks the check-in approved and creates a result with the submitted time" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.check_in!(event: event, user: user, status: "pending")
    check_in.record_time!("52:25")

    check_in.approve!

    assert check_in.reload.approved?
    assert_equal 52 * 60 + 25, event.results.find_by!(user: user).time
  end

  test "approve! creates a participant result when no time was submitted" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.check_in!(event: event, user: user, status: "pending")

    check_in.approve!

    assert_nil event.results.find_by!(user: user).time
  end

  test "approve! keeps an existing result" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.check_in!(event: event, user: user, status: "pending")
    check_in.record_time!("52:25")
    event.results.create!(user: user, time: 3000)

    assert_no_difference "Result.count" do
      check_in.approve!
    end

    assert_equal 3000, event.results.find_by!(user: user).time
  end

  test "withdraw! removes the check-in and the user's result for that event" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.check_in!(event: event, user: user)

    assert_difference [ "CheckIn.count", "Result.count" ], -1 do
      check_in.withdraw!
    end

    assert_not event.results.exists?(user: user)
  end

  test "withdraw! leaves the user's results for other events alone" do
    user = users(:one)
    check_in = CheckIn.check_in!(event: events(:draft_event), user: user)

    check_in.withdraw!

    assert events(:one).results.exists?(user: user)
  end

  test "withdraw! of a pending check-in removes only the check-in" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.check_in!(event: event, user: user, status: "pending")

    assert_difference "CheckIn.count", -1 do
      assert_no_difference "Result.count" do
        check_in.withdraw!
      end
    end
  end

  test "submitted_time_string formats the submitted time" do
    check_in = CheckIn.new(submitted_time: 52 * 60 + 25)

    assert_equal "52:25", check_in.submitted_time_string
  end

  test "submitted_time_string shows a participant when no time was submitted" do
    assert_equal "Participant", CheckIn.new.submitted_time_string
  end
end
