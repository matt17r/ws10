require "application_system_test_case"

class EventsTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit events_url
    assert_selector "h1", text: "Events"
  end

  test "index shows only ready events" do
    ready_event = events(:one)
    draft_event = events(:draft_event)

    visit events_url

    assert_text ready_event.location
    assert_no_text draft_event.location
  end

  test "index shows abandoned and cancelled events with badges" do
    abandoned_event = events(:one)
    cancelled_event = events(:two)
    abandoned_event.update!(status: "abandoned", cancellation_reason: "Heavy rain")
    cancelled_event.update!(status: "cancelled", cancellation_reason: "Flooding")

    visit events_url

    assert_text abandoned_event.location
    assert_text cancelled_event.location
    assert_text "CANCELLED", count: 2
    assert_text "Heavy rain"
    assert_text "Flooding"
  end

  test "home page shows CANCELLED banner for abandoned events" do
    abandoned_event = events(:draft_event)
    abandoned_event.update!(
      status: "abandoned",
      date: 1.day.from_now,
      cancellation_reason: "Due to heavy rain"
    )

    visit root_url

    assert_text "CANCELLED"
    assert_text "Due to heavy rain"
    assert_no_text "Next Event"
  end

  test "home page skips cancelled events" do
    cancelled_event = events(:draft_event)
    cancelled_event.update!(status: "cancelled", date: 1.day.from_now)

    next_event = events(:one)
    next_event.update!(status: "draft", date: 2.days.from_now)

    visit root_url

    assert_text next_event.location
    assert_no_text cancelled_event.location
  end

  test "course page shows cancellation banner for abandoned events" do
    location = locations(:bungarribee)
    abandoned_event = events(:draft_event)
    abandoned_event.update!(
      status: "abandoned",
      date: 1.day.from_now,
      location: location,
      cancellation_reason: "Weather conditions"
    )

    visit course_url(location.slug)

    assert_text "Event Cancelled"
    assert_text "Weather conditions"
  end

  test "event show page displays cancellation banner" do
    event = events(:one)
    event.update!(status: "abandoned", cancellation_reason: "Severe weather")

    visit event_url(event)

    assert_text "This event was cancelled"
    assert_text "Severe weather"
  end
end
