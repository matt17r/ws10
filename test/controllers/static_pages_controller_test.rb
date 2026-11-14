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

  test "support page redirects to about" do
    get "/support"

    assert_redirected_to about_path
  end

  test "pages do not ask regular runners for financial support" do
    user = users(:one)
    Result.create!(event: events(:two), user: user, time: 2_600)
    Result.create!(event: events(:draft_event), user: user, time: 2_700)
    sign_in_as(user)

    [ root_path, about_path, event_path(events(:one).number) ].each do |path|
      get path

      assert_response :success
      assert_select "a[href=?]", "/support", count: 0
      assert_no_match(/support (ws10|financially)/i, response.body, "#{path} mentions financial support")
    end
  end
end
