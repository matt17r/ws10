require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "sign up page warns that WS10 is winding down" do
    get sign_up_path

    assert_response :success
    assert_select "[role=alert]", text: /winding down/i
  end

  test "sign up page does not offer the email newsletter" do
    get sign_up_path

    assert_select "input[name=?]", "user[newsletter_opt_in]", count: 0
  end

  test "signing up does not opt the user in to the newsletter even if asked to" do
    assert_no_enqueued_jobs only: NewsletterSubscribeJob do
      post sign_up_path, params: { user: {
        name: "Final Runner", display_name: "Final Runner", email_address: "final@example.com",
        password: "password123", password_confirmation: "password123", newsletter_opt_in: "1"
      } }
    end

    assert_not User.find_by!(email_address: "final@example.com").newsletter_opt_in?
  end
end
