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

  test "does nothing on a host that isn't the active origin" do
    event = events(:draft_event)
    original_check = CloseOutEventsJob.active_origin_check
    CloseOutEventsJob.active_origin_check = -> { false }

    travel_to event.check_in_opens_at + 1.day do
      CloseOutEventsJob.perform_now
    end

    assert event.reload.draft?
  ensure
    CloseOutEventsJob.active_origin_check = original_check
  end

  test "treats every host as the active origin outside production" do
    assert CloseOutEventsJob.active_origin_check.call
  end

  test "runs every morning at 7am Sydney time in production" do
    schedule = YAML.load_file(Rails.root.join("config/recurring.yml")).dig("production", "close_out_events")
    cron = Fugit.parse_cron(schedule["schedule"])

    assert_equal "CloseOutEventsJob", schedule["class"]
    assert_equal ActiveSupport::TimeZone["Sydney"].local(2025, 5, 30, 7, 0), cron.next_time(Time.utc(2025, 5, 29, 12, 0)).to_t
  end
end
