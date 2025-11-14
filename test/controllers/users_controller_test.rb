require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "unauthenticated user visiting profile/results should be redirected to sign in" do
    get my_results_url

    assert_redirected_to sign_in_path
  end

  test "authenticated user visiting profile/results should be redirected to their own results page" do
    user = users(:one)
    sign_in_as(user)

    get my_results_url

    assert_redirected_to user_results_path(barcode: user.barcode_string)
  end

  test "after signing in, user should be redirected to profile/results if that was the requested page" do
    user = users(:one)

    get my_results_url
    assert_redirected_to sign_in_path

    post sign_in_url, params: { email_address: user.email_address, password: "password" }

    assert_redirected_to my_results_url
  end
end
