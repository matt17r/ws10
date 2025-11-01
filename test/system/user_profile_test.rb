require "application_system_test_case"

class UserProfileTest < ApplicationSystemTestCase
  test "signed in user can view profile and navigate to their results" do
    user = users(:one)
    sign_in_as user

    visit user_url
    assert_selector "h1", text: "Profile"

    click_link "View All Results"

    assert_selector "h1", text: "#{user.emoji} #{user.display_name}"
    assert_current_path user_results_path(user.barcode_string)
  end
end
