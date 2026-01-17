require "test_helper"

class EventTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  test "should create valid event" do
    event = Event.new(
      number: 10,
      date: Date.current,
      location: locations(:bungarribee),
      description: "Test Event"
    )
    assert event.valid?
    assert event.save
  end

  test "should have associations" do
    event = events(:one)
    assert_respond_to event, :results
    assert_respond_to event, :volunteers
    assert_respond_to event, :finish_positions
    assert_respond_to event, :finish_times
    assert_respond_to event, :finished_users
    assert_respond_to event, :check_ins
    assert_respond_to event, :checked_in_users
  end

  test "should require date" do
    event = Event.new(number: 1, location: locations(:bungarribee))
    assert_not event.valid?
    assert_includes event.errors[:date], "can't be blank"
  end

  test "should require number" do
    event = Event.new(date: Date.current, location: locations(:bungarribee))
    assert_not event.valid?
    assert_includes event.errors[:number], "is not a number"
  end

  test "should require number to be integer" do
    event = Event.new(number: 1.5, date: Date.current, location: locations(:bungarribee))
    assert_not event.valid?
    assert_includes event.errors[:number], "must be an integer"
  end

  test "should require number to be greater than zero" do
    event = Event.new(number: 0, date: Date.current, location: locations(:bungarribee))
    assert_not event.valid?
    assert_includes event.errors[:number], "must be greater than 0"

    event.number = -1
    assert_not event.valid?
    assert_includes event.errors[:number], "must be greater than 0"
  end

  test "not_finalised scope should return events not finalised" do
    ready_event = events(:one)
    draft_event = events(:draft_event)

    ready_event.update!(status: "finalised")
    draft_event.update!(status: "draft")

    not_finalised_events = Event.not_finalised
    assert_includes not_finalised_events, draft_event
    assert_not_includes not_finalised_events, ready_event
  end

  test "to_s should format event number and date" do
    event = Event.new(number: 5, date: Date.new(2025, 6, 15))
    expected = "#5 - 15 Jun"
    assert_equal expected, event.to_s
  end

  test "to_param should return number as string" do
    event = Event.new(number: 42)
    assert_equal "42", event.to_param
  end

  test "unplaced_users should return users not in finish_positions" do
    event = events(:one)
    user_with_result = users(:one)
    user_without_result = users(:two)

    event.finish_positions.create!(user: user_with_result, position: 1)

    unplaced = event.unplaced_users
    assert_not_includes unplaced, user_with_result
    assert_includes unplaced, user_without_result
  end

  test "should send emails when status changes to finalised" do
    event = events(:draft_event)
    event.update!(status: "draft")

    result_with_time = event.results.create!(user: users(:one), time: 1600)
    result_without_time = event.results.create!(user: users(:two))

    assert_enqueued_jobs 3 do  # AwardBadgesJob + 2 email jobs
      event.update!(status: "finalised")
    end
  end

  test "should not send emails when status stays finalised" do
    event = events(:one)
    event.update!(status: "finalised")

    assert_no_enqueued_jobs do
      event.update!(description: "Updated description")
    end
  end

  test "should not send emails when status changes from finalised to draft" do
    event = events(:one)
    event.update!(status: "finalised")

    assert_no_enqueued_jobs do
      event.update!(status: "draft")
    end
  end

  test "should send different email types based on result time" do
    event = events(:draft_event)
    event.update!(status: "draft")

    result_with_time = event.results.create!(user: users(:one), time: 1800)
    result_without_time = event.results.create!(user: users(:two))

    assert_enqueued_jobs 3 do  # AwardBadgesJob + 2 email jobs
      event.update!(status: "finalised")
    end
  end

  test "should handle events with no results when marking finalised" do
    event = events(:draft_event)
    event.results.destroy_all

    assert_enqueued_jobs 1 do  # Only AwardBadgesJob, no email jobs
      event.update!(status: "finalised")
    end
  end

  test "should handle large event numbers" do
    event = Event.new(number: 999999, date: Date.current, location: locations(:bungarribee))
    assert event.valid?
  end

  test "should handle future and past dates" do
    future_event = Event.new(number: 1, date: 1.year.from_now, location: locations(:bungarribee))
    past_event = Event.new(number: 2, date: 1.year.ago, location: locations(:nepean))

    assert future_event.valid?
    assert past_event.valid?
  end

  test "unplaced_users should work with no finish_positions" do
    event = events(:one)
    event.finish_positions.destroy_all

    unplaced = event.unplaced_users
    assert_includes unplaced, users(:one)
    assert_includes unplaced, users(:two)
  end

  test "unplaced_users should handle users with multiple results across events" do
    user = users(:three)

    events(:one).results.create!(user: user, time: 1600)
    events(:two).results.create!(user: user, time: 1650)

    unplaced = events(:draft_event).unplaced_users
    user_count = unplaced.select { |u| u.id == user.id }.count
    assert_equal 1, user_count
  end

  test "active? returns true when status is in_progress" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    assert event.active?
  end

  test "active? returns false when status is draft" do
    event = events(:draft_event)
    event.update!(status: "draft")
    assert_not event.active?
  end

  test "active? returns false when status is finalised" do
    event = events(:draft_event)
    event.update!(status: "finalised")
    assert_not event.active?
  end

  test "activate! sets status to in_progress" do
    event = events(:draft_event)
    event.update!(status: "draft")
    event.activate!
    assert event.reload.in_progress?
    assert event.active?
  end

  test "activate! deactivates other active events" do
    event1 = events(:one)
    event2 = events(:draft_event)

    event1.update!(status: "in_progress")
    event2.update!(status: "draft")

    event2.activate!

    assert event2.reload.active?
    assert_not event1.reload.active?
    assert event1.reload.draft?
  end

  test "deactivate! sets status to draft" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    event.deactivate!
    assert event.reload.draft?
    assert_not event.active?
  end

  test "enum provides draft? predicate" do
    event = events(:draft_event)
    event.update!(status: "draft")
    assert event.draft?
    assert_not event.in_progress?
    assert_not event.finalised?
  end

  test "enum provides in_progress? predicate" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    assert event.in_progress?
    assert_not event.draft?
    assert_not event.finalised?
  end

  test "enum provides finalised? predicate" do
    event = events(:draft_event)
    event.update!(status: "finalised")
    assert event.finalised?
    assert_not event.draft?
    assert_not event.in_progress?
  end

  test "has many check_ins" do
    event = events(:draft_event)
    user = users(:one)

    check_in = event.check_ins.create!(user: user, checked_in_at: Time.current)

    assert_includes event.check_ins, check_in
  end

  test "has many checked_in_users through check_ins" do
    event = events(:draft_event)
    user = users(:one)

    event.check_ins.create!(user: user, checked_in_at: Time.current)

    assert_includes event.checked_in_users, user
  end

  test "checked_in_unplaced_users returns only users who checked in" do
    event = events(:draft_event)
    checked_in_user = users(:one)
    not_checked_in_user = users(:two)

    event.check_ins.create!(user: checked_in_user, checked_in_at: Time.current)

    checked_in_unplaced = event.checked_in_unplaced_users

    assert_includes checked_in_unplaced, checked_in_user
    assert_not_includes checked_in_unplaced, not_checked_in_user
  end

  test "checked_in_unplaced_users excludes users who already have finish positions" do
    event = events(:draft_event)
    checked_in_user = users(:one)
    checked_in_placed_user = users(:two)

    event.check_ins.create!(user: checked_in_user, checked_in_at: Time.current)
    event.check_ins.create!(user: checked_in_placed_user, checked_in_at: Time.current)

    event.finish_positions.create!(user: checked_in_placed_user, position: 1)

    checked_in_unplaced = event.checked_in_unplaced_users

    assert_includes checked_in_unplaced, checked_in_user
    assert_not_includes checked_in_unplaced, checked_in_placed_user
  end

  test "checked_in_unplaced_users returns empty when no check-ins" do
    event = events(:draft_event)

    checked_in_unplaced = event.checked_in_unplaced_users

    assert_empty checked_in_unplaced
  end

  test "enum provides abandoned? predicate" do
    event = events(:draft_event)
    event.update!(status: "abandoned")
    assert event.abandoned?
    assert_not event.draft?
    assert_not event.in_progress?
    assert_not event.finalised?
    assert_not event.cancelled?
  end

  test "enum provides cancelled? predicate" do
    event = events(:draft_event)
    event.update!(status: "cancelled")
    assert event.cancelled?
    assert_not event.draft?
    assert_not event.in_progress?
    assert_not event.finalised?
    assert_not event.abandoned?
  end

  test "upcoming_for_home scope includes abandoned events" do
    draft_event = events(:draft_event)
    abandoned_event = events(:one)
    cancelled_event = events(:two)

    draft_event.update!(status: "draft")
    abandoned_event.update!(status: "abandoned")
    cancelled_event.update!(status: "cancelled")

    upcoming = Event.upcoming_for_home
    assert_includes upcoming, draft_event
    assert_includes upcoming, abandoned_event
    assert_not_includes upcoming, cancelled_event
  end

  test "not_finalised scope excludes abandoned and cancelled events" do
    draft_event = events(:draft_event)
    abandoned_event = events(:one)
    cancelled_event = events(:two)

    draft_event.update!(status: "draft")
    abandoned_event.update!(status: "abandoned")
    cancelled_event.update!(status: "cancelled")

    not_finalised = Event.not_finalised
    assert_includes not_finalised, draft_event
    assert_not_includes not_finalised, abandoned_event
    assert_not_includes not_finalised, cancelled_event
  end

  test "abandon! works for draft events" do
    event = events(:draft_event)
    event.update!(status: "draft")
    event.abandon!
    assert event.reload.abandoned?
  end

  test "abandon! works for in_progress events" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    event.abandon!
    assert event.reload.abandoned?
  end

  test "abandon! fails for finalised events" do
    event = events(:draft_event)
    event.update!(status: "finalised")

    error = assert_raises(RuntimeError) do
      event.abandon!
    end
    assert_equal "Cannot abandon a finalised event", error.message
  end

  test "archive_as_cancelled! works for abandoned events" do
    event = events(:draft_event)
    event.update!(status: "abandoned")
    event.archive_as_cancelled!
    assert event.reload.cancelled?
  end

  test "archive_as_cancelled! fails for non-abandoned events" do
    event = events(:draft_event)
    event.update!(status: "draft")

    error = assert_raises(RuntimeError) do
      event.archive_as_cancelled!
    end
    assert_equal "Can only archive abandoned events", error.message
  end

  test "activate! fails for abandoned events" do
    event = events(:draft_event)
    event.update!(status: "abandoned")

    error = assert_raises(RuntimeError) do
      event.activate!
    end
    assert_equal "Cannot activate an abandoned or cancelled event", error.message
  end

  test "activate! fails for cancelled events" do
    event = events(:draft_event)
    event.update!(status: "cancelled")

    error = assert_raises(RuntimeError) do
      event.activate!
    end
    assert_equal "Cannot activate an abandoned or cancelled event", error.message
  end

  test "should not send emails when transitioning to abandoned" do
    event = events(:draft_event)
    event.update!(status: "draft")
    event.results.create!(user: users(:one), time: 1600)

    assert_no_enqueued_jobs do
      event.update!(status: "abandoned")
    end
  end

  test "should not send emails when transitioning to cancelled" do
    event = events(:draft_event)
    event.update!(status: "abandoned")
    event.results.create!(user: users(:one), time: 1600)

    assert_no_enqueued_jobs do
      event.update!(status: "cancelled")
    end
  end
end
