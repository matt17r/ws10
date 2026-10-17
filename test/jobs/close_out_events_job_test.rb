require "test_helper"
require "fugit"

class CloseOutEventsJobTest < ActiveJob::TestCase
  test "finalises yesterday's event" do
    event = events(:draft_event)

    travel_to event.check_in_opens_at + 1.day do
      CloseOutEventsJob.perform_now
    end

    assert event.reload.finalised?
  end

  test "leaves today's event open" do
    event = events(:draft_event)

    travel_to event.check_in_opens_at + 1.hour do
      CloseOutEventsJob.perform_now
    end

    assert event.reload.draft?
  end

  test "catches up on an event from several days ago" do
    event = events(:draft_event)

    travel_to event.check_in_opens_at + 5.days do
      CloseOutEventsJob.perform_now
    end

    assert event.reload.finalised?
  end

  test "first runs at 7am Sydney time in production" do
    schedule = YAML.load_file(Rails.root.join("config/recurring.yml")).dig("production", "close_out_events")
    cron = Fugit.parse_cron(schedule["schedule"])
    sydney = ActiveSupport::TimeZone["Sydney"]

    assert_equal "CloseOutEventsJob", schedule["class"]
    assert_equal sydney.local(2025, 5, 30, 7, 0), cron.next_time(sydney.local(2025, 5, 29, 23, 0)).to_t
  end

  test "retries hourly through the day in production" do
    schedule = YAML.load_file(Rails.root.join("config/recurring.yml")).dig("production", "close_out_events")
    cron = Fugit.parse_cron(schedule["schedule"])
    sydney = ActiveSupport::TimeZone["Sydney"]

    assert_equal sydney.local(2025, 5, 30, 8, 0), cron.next_time(sydney.local(2025, 5, 30, 7, 0)).to_t
  end
end
