require "test_helper"

class OgImageGeneratorServiceTest < ActiveSupport::TestCase
  setup do
    @event = events(:one)
  end

  test "stats returns correct participant count" do
    service = OgImageGeneratorService.new(@event)
    s = service.stats

    assert_equal @event.results.count + @event.volunteers.count, s[:participant_count]
  end

  test "stats returns correct event number and location name" do
    service = OgImageGeneratorService.new(@event)
    s = service.stats

    assert_equal @event.number, s[:event_number]
    assert_equal @event.location.name, s[:location_name]
  end

  test "stats counts first timers correctly" do
    user = users(:one)
    user.results.destroy_all

    first_event = Event.create!(number: 50, date: 3.weeks.ago, location: locations(:bungarribee), status: "finalised")
    Result.create!(user: user, event: first_event, time: 2000)

    later_event = Event.create!(number: 51, date: 2.weeks.ago, location: locations(:bungarribee), status: "finalised")
    Result.create!(user: user, event: later_event, time: 1800)

    service = OgImageGeneratorService.new(first_event)
    s = service.stats

    assert_equal 1, s[:first_timer_count]
  end

  test "stats counts personal bests correctly" do
    user = users(:one)
    user.results.destroy_all

    first_event = Event.create!(number: 60, date: 3.weeks.ago, location: locations(:bungarribee), status: "finalised")
    Result.create!(user: user, event: first_event, time: 2000)

    second_event = Event.create!(number: 61, date: 2.weeks.ago, location: locations(:bungarribee), status: "finalised")
    Result.create!(user: user, event: second_event, time: 1900)

    service = OgImageGeneratorService.new(second_event)
    s = service.stats

    assert_equal 1, s[:pb_count]
  end

  test "stats detects new course record" do
    location = locations(:nepean)
    user = users(:one)
    user.results.destroy_all

    previous_event = Event.create!(number: 70, date: 3.weeks.ago, location: location, status: "finalised")
    Result.create!(user: user, event: previous_event, time: 2000)

    record_event = Event.create!(number: 71, date: 2.weeks.ago, location: location, status: "finalised")
    Result.create!(user: user, event: record_event, time: 1800)

    service = OgImageGeneratorService.new(record_event)
    s = service.stats

    assert s[:new_course_record]
  end

  test "stats detects new ws10 record" do
    location = locations(:nepean)
    user = users(:one)
    user.results.destroy_all

    previous_event = Event.create!(number: 80, date: 3.weeks.ago, location: locations(:bungarribee), status: "finalised")
    Result.create!(user: user, event: previous_event, time: 2000)

    record_event = Event.create!(number: 81, date: 2.weeks.ago, location: location, status: "finalised")
    Result.create!(user: user, event: record_event, time: 1800)

    service = OgImageGeneratorService.new(record_event)
    s = service.stats

    assert s[:new_ws10_record]
    assert s[:new_course_record]
  end

  test "stats reports no new course record when previous event at location was faster" do
    location = locations(:nepean)
    user = users(:one)
    user.results.destroy_all

    previous_event = Event.create!(number: 90, date: 3.weeks.ago, location: location, status: "finalised")
    Result.create!(user: user, event: previous_event, time: 1700)

    slower_event = Event.create!(number: 91, date: 2.weeks.ago, location: location, status: "finalised")
    Result.create!(user: user, event: slower_event, time: 2000)

    service = OgImageGeneratorService.new(slower_event)
    s = service.stats

    assert_not s[:new_course_record]
    assert_equal "28:20", s[:course_record_str]
  end

  test "stats detects new course record but not ws10 record when a faster time exists elsewhere" do
    nepean = locations(:nepean)
    bungarribee = locations(:bungarribee)
    user = users(:one)
    user.results.destroy_all

    faster_ws10_event = Event.create!(number: 92, date: 3.weeks.ago, location: bungarribee, status: "finalised")
    Result.create!(user: user, event: faster_ws10_event, time: 1600)

    course_record_event = Event.create!(number: 93, date: 2.weeks.ago, location: nepean, status: "finalised")
    Result.create!(user: user, event: course_record_event, time: 1800)

    service = OgImageGeneratorService.new(course_record_event)
    s = service.stats

    assert s[:new_course_record]
    assert_not s[:new_ws10_record]
  end

  test "stats counts badges for the event" do
    badge = badges(:centurion_bronze)
    user = users(:one)
    UserBadge.create!(user: user, badge: badge, event: @event, earned_at: Time.current)

    service = OgImageGeneratorService.new(@event)
    s = service.stats

    assert s[:badge_count] >= 1
  end

  test "build_svg returns svg string with event details" do
    service = OgImageGeneratorService.new(@event)
    svg = service.build_svg

    assert_includes svg, "Western Sydney 10"
    assert_includes svg, "Event ##{@event.number}"
    assert_includes svg, "ws10.run"
    assert_includes svg, "RUNNERS"
    assert_includes svg, "FIRST TIMERS"
    assert_includes svg, "PERSONAL BESTS"
  end

  test "build_svg includes new course record text when applicable" do
    location = locations(:nepean)
    user = users(:one)
    user.results.destroy_all

    record_event = Event.create!(number: 95, date: 1.week.ago, location: location, status: "finalised")
    Result.create!(user: user, event: record_event, time: 1800)

    service = OgImageGeneratorService.new(record_event)
    svg = service.build_svg

    assert_includes svg, "NEW"
    assert_includes svg, "RECORD"
  end
end
