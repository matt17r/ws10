require "test_helper"

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get home page when visiting root url" do
    get root_url
    assert_response :success
  end

  test "admin user should be able to view admin dashboard" do
    admin_user = users(:one)
    sign_in_as(admin_user)

    get dashboard_url
    assert_response :success
    assert_select "a[href=?]", admin_events_path, text: "Manage events"
  end

  test "about page has an faq entry for finding the course" do
    get about_url

    assert_response :success
    assert_select "dt#find-the-course"
  end

  test "home shows a check-in button while the next event is open for check-in" do
    event = events(:draft_event)

    travel_to event.check_in_opens_at + 15.minutes do
      get root_url
    end

    assert_select "a[href=?]", check_in_path, text: "Check In Now!"
  end

  test "home offers to check others in once the runner has checked in" do
    event = events(:draft_event)
    user = users(:three)
    CheckIn.check_in!(event: event, user: user)
    sign_in_as user

    travel_to event.check_in_opens_at + 15.minutes do
      get root_url
    end

    assert_select "a[href=?]", check_in_path, text: "Check Others In"
  end

  test "home has no check-in button before the window opens" do
    event = events(:draft_event)

    travel_to event.check_in_opens_at - 1.day do
      get root_url
    end

    assert_select "a[href=?]", check_in_path, count: 0
  end

  test "admin dashboard offers the permanent check-in URL to copy" do
    sign_in_as users(:one)

    get dashboard_url

    assert_select "[data-clipboard-target=source]", text: check_in_url
  end
end
