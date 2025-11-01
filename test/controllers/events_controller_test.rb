require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  test "should get index without authentication" do
    get events_url
    assert_response :success
  end

  test "index should only show ready events" do
    ready_event = events(:one)
    draft_event = events(:draft_event)

    get events_url
    assert_response :success

    events_shown = assigns(:events)
    assert events_shown.all?(&:results_ready?)
    assert_includes events_shown, ready_event
    assert_not_includes events_shown, draft_event
  end

  test "should show ready event without authentication" do
    event = events(:one)

    get event_url(event)
    assert_response :success
  end

  test "should redirect to results for non-existent event" do
    get event_url(number: 999)
    assert_redirected_to results_path
  end

  test "should require admin for new" do
    get new_admin_event_url
    assert_response :not_found
  end

  test "should require admin for create" do
    event_params = { date: Date.current, description: "Test event", location: "Test location", number: 99, results_ready: false }

    assert_no_difference("Event.count") do
      post admin_events_url, params: { event: event_params }
    end
    assert_response :not_found
  end

  test "should require admin for edit" do
    event = events(:one)

    get edit_admin_event_url(number: event.number)
    assert_response :not_found
  end

  test "should require admin for update" do
    event = events(:one)

    patch admin_event_url(number: event.number), params: { event: { description: "Updated description" } }
    assert_response :not_found
  end

  test "admin should be able to update event" do
    admin_user = users(:one)
    sign_in_as(admin_user)
    event = events(:one)

    patch admin_event_url(number: event.number), params: { event: { description: "Updated description" } }
    assert_redirected_to event_url(number: event.number)

    event.reload
    assert_equal "Updated description", event.description
  end

  test "should require admin for destroy" do
    event = events(:one)

    assert_no_difference("Event.count") do
      delete admin_event_url(number: event.number)
    end
    assert_response :not_found
  end
end
