require "test_helper"

class CheckInFlowTest < ActionDispatch::IntegrationTest
  test "complete check-in flow for unauthenticated user" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    token = CheckIn.token_for_event(event.number)
    user = users(:one)

    get check_in_url(token)
    assert_response :success

    post check_in_url(token)
    assert_redirected_to sign_in_path

    post sign_in_url, params: {
      email_address: user.email_address,
      password: "password"
    }

    assert_redirected_to check_in_path(token)

    follow_redirect!
    assert_difference "CheckIn.count", 1 do
      post check_in_url(token)
    end

    assert_redirected_to user_path
    follow_redirect!
  end

  test "complete check-in flow for authenticated user" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    token = CheckIn.token_for_event(event.number)
    user = users(:one)
    sign_in_as user

    get check_in_url(token)
    assert_response :success

    assert_difference "CheckIn.count", 1 do
      post check_in_url(token)
    end

    assert_redirected_to user_path
    follow_redirect!

    get check_in_url(token)
    assert_response :success
  end

  test "user cannot check in twice to same event" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    token = CheckIn.token_for_event(event.number)
    user = users(:one)
    sign_in_as user

    post check_in_url(token)
    assert_redirected_to user_path

    assert_no_difference "CheckIn.count" do
      post check_in_url(token)
    end

    assert_redirected_to user_path
    assert_match(/Could not check in/, flash[:alert])
  end

  test "user can check in to multiple events" do
    event1 = events(:one)
    event2 = events(:two)
    user = users(:one)
    sign_in_as user

    event1.update!(status: "in_progress")
    token1 = CheckIn.token_for_event(event1.number)
    post check_in_url(token1)
    assert_redirected_to user_path

    event1.update!(status: "finalised")
    event2.update!(status: "in_progress")
    token2 = CheckIn.token_for_event(event2.number)

    assert_difference "CheckIn.count", 1 do
      post check_in_url(token2)
    end

    assert_redirected_to user_path
  end

  test "multiple users can check in to same event" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    token = CheckIn.token_for_event(event.number)
    user1 = users(:one)
    user2 = users(:two)

    sign_in_as user1
    post check_in_url(token)
    assert_redirected_to user_path
    delete sign_out_url

    sign_in_as user2
    assert_difference "CheckIn.count", 1 do
      post check_in_url(token)
    end

    assert_redirected_to user_path

    assert_equal 2, event.check_ins.count
  end
end
