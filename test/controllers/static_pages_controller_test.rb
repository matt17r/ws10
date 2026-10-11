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
end
