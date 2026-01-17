require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  test "should get index without authentication" do
    get events_url
    assert_response :success
  end

  test "index should only show finalised events" do
    ready_event = events(:one)
    draft_event = events(:draft_event)

    get events_url
    assert_response :success

    events_shown = assigns(:events)
    assert events_shown.all?(&:finalised?)
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
    event_params = { date: Date.current, description: "Test event", location: "Test location", number: 99, status: "draft" }

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

  test "non-admin users cannot view draft events" do
    event = events(:draft_event)
    event.update!(status: "draft")

    get event_url(event)
    assert_redirected_to results_path
  end

  test "admin users can view draft events" do
    admin_user = users(:one)
    sign_in_as(admin_user)
    event = events(:draft_event)
    event.update!(status: "draft")

    get event_url(event)
    assert_response :success
  end

  test "non-admin users can view in_progress events" do
    event = events(:draft_event)
    event.update!(status: "in_progress")

    get event_url(event)
    assert_response :success
  end

  test "non-admin users can view finalised events" do
    event = events(:one)
    event.update!(status: "finalised")

    get event_url(event)
    assert_response :success
  end

  test "index should show abandoned and cancelled events to public" do
    abandoned_event = events(:one)
    cancelled_event = events(:two)
    draft_event = events(:draft_event)

    abandoned_event.update!(status: "abandoned")
    cancelled_event.update!(status: "cancelled")
    draft_event.update!(status: "draft")

    get events_url
    assert_response :success

    events_shown = assigns(:events)
    assert_includes events_shown, abandoned_event
    assert_includes events_shown, cancelled_event
    assert_not_includes events_shown, draft_event
  end

  test "non-admin users can view abandoned events" do
    event = events(:draft_event)
    event.update!(status: "abandoned")

    get event_url(event)
    assert_response :success
  end

  test "non-admin users can view cancelled events" do
    event = events(:draft_event)
    event.update!(status: "cancelled")

    get event_url(event)
    assert_response :success
  end

  test "should require admin for abandon" do
    event = events(:draft_event)
    event.update!(status: "draft")

    post abandon_admin_event_url(number: event.number)
    assert_response :not_found
    event.reload
    assert_not event.abandoned?
  end

  test "admin should be able to abandon event" do
    admin_user = users(:one)
    sign_in_as(admin_user)
    event = events(:draft_event)
    event.update!(status: "draft")

    post abandon_admin_event_url(number: event.number)
    assert_redirected_to dashboard_path

    event.reload
    assert event.abandoned?
  end

  test "should require admin for archive" do
    event = events(:draft_event)
    event.update!(status: "abandoned")

    post archive_admin_event_url(number: event.number)
    assert_response :not_found
    event.reload
    assert_not event.cancelled?
  end

  test "admin should be able to archive abandoned event" do
    admin_user = users(:one)
    sign_in_as(admin_user)
    event = events(:draft_event)
    event.update!(status: "abandoned")

    post archive_admin_event_url(number: event.number)
    assert_redirected_to dashboard_path

    event.reload
    assert event.cancelled?
  end
end
