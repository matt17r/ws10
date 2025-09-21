require "test_helper"

class EventTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  test "should create valid event" do
    event = Event.new(
      number: 10,
      date: Date.current,
      location: "Test Location",
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
  end

  test "should require date" do
    event = Event.new(number: 1, location: "Test Location")
    assert_not event.valid?
    assert_includes event.errors[:date], "can't be blank"
  end

  test "should require location" do
    event = Event.new(number: 1, date: Date.current)
    assert_not event.valid?
    assert_includes event.errors[:location], "can't be blank"
  end

  test "should require number" do
    event = Event.new(date: Date.current, location: "Test Location")
    assert_not event.valid?
    assert_includes event.errors[:number], "is not a number"
  end

  test "should require number to be integer" do
    event = Event.new(number: 1.5, date: Date.current, location: "Test Location")
    assert_not event.valid?
    assert_includes event.errors[:number], "must be an integer"
  end

  test "should require number to be greater than zero" do
    event = Event.new(number: 0, date: Date.current, location: "Test Location")
    assert_not event.valid?
    assert_includes event.errors[:number], "must be greater than 0"

    event.number = -1
    assert_not event.valid?
    assert_includes event.errors[:number], "must be greater than 0"
  end

  test "in_progress scope should return events not ready" do
    ready_event = events(:one)
    draft_event = events(:draft_event)

    ready_event.update!(results_ready: true)
    draft_event.update!(results_ready: false)

    in_progress_events = Event.in_progress
    assert_includes in_progress_events, draft_event
    assert_not_includes in_progress_events, ready_event
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

  test "should send emails when results_ready changes from false to true" do
    event = events(:draft_event)
    event.update!(results_ready: false)

    result_with_time = event.results.create!(user: users(:one), time: 1600)
    result_without_time = event.results.create!(user: users(:two))

    assert_enqueued_jobs 2 do
      event.update!(results_ready: true)
    end
  end

  test "should not send emails when results_ready stays true" do
    event = events(:one)
    event.update!(results_ready: true)

    assert_no_enqueued_jobs do
      event.update!(description: "Updated description")
    end
  end

  test "should not send emails when results_ready changes from true to false" do
    event = events(:one)
    event.update!(results_ready: true)

    assert_no_enqueued_jobs do
      event.update!(results_ready: false)
    end
  end

  test "should send different email types based on result time" do
    event = events(:draft_event)
    event.update!(results_ready: false)

    result_with_time = event.results.create!(user: users(:one), time: 1800)
    result_without_time = event.results.create!(user: users(:two))

    assert_enqueued_jobs 2 do
      event.update!(results_ready: true)
    end
  end

  test "should handle events with no results when marking ready" do
    event = events(:draft_event)
    event.results.destroy_all

    assert_no_enqueued_jobs do
      event.update!(results_ready: true)
    end
  end

  test "should handle large event numbers" do
    event = Event.new(number: 999999, date: Date.current, location: "Test")
    assert event.valid?
  end

  test "should handle future and past dates" do
    future_event = Event.new(number: 1, date: 1.year.from_now, location: "Future")
    past_event = Event.new(number: 2, date: 1.year.ago, location: "Past")

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

  test "unplaced_users should handle users with multiple results" do
    event = events(:one)
    user = users(:one)

    event.results.create!(user: user, time: 1600)
    event.results.create!(user: user, time: 1650)

    unplaced = event.unplaced_users
    user_count = unplaced.select { |u| u.id == user.id }.count
    assert_equal 1, user_count
  end
end
