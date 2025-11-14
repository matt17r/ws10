require "application_system_test_case"

class UserProfileTest < ApplicationSystemTestCase
  test "signed in user can view profile and navigate to their results" do
    user = users(:one)
    sign_in_as user

    visit user_url
    assert_selector "h1", text: "Profile"

    visit user_results_path(user.barcode_string)

    assert_selector "h2", text: "Results"
  end

  test "signed in user can access their results via profile/results" do
    user = users(:one)
    sign_in_as user

    visit my_results_path

    assert_selector "h2", text: "Results"
  end
end
