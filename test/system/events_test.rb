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
end
