require "test_helper"

class CheckInsControllerTest < ActionDispatch::IntegrationTest
  test "show displays check-in page for valid token and active event" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    token = CheckIn.token_for_event(event.number)

    get check_in_url(token)

    assert_response :success
  end

  test "show indicates already checked in when user is checked in" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    user = users(:one)
    sign_in_as user
    CheckIn.create!(user: user, event: event, checked_in_at: Time.current)
    token = CheckIn.token_for_event(event.number)

    get check_in_url(token)

    assert_response :success
    assert assigns(:already_checked_in)
  end

  test "show does not indicate already checked in when user is not checked in" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    user = users(:one)
    sign_in_as user
    token = CheckIn.token_for_event(event.number)

    get check_in_url(token)

    assert_response :success
    assert_not assigns(:already_checked_in)
  end

  test "show sets already_checked_in to nil when not authenticated" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    token = CheckIn.token_for_event(event.number)

    get check_in_url(token)

    assert_response :success
    assert_nil assigns(:already_checked_in)
  end

  test "show redirects when no active event" do
    token = CheckIn.token_for_event(999)

    get check_in_url(token)

    assert_redirected_to root_path
    assert_equal "No active event for check-in.", flash[:alert]
  end

  test "show returns error for invalid token" do
    event = events(:draft_event)
    event.update!(status: "in_progress")

    assert_raises(ActionController::UrlGenerationError) do
      get check_in_url("invalidtoken")
    end
  end

  test "create redirects to sign in when not authenticated" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    token = CheckIn.token_for_event(event.number)

    post check_in_url(token)

    assert_redirected_to sign_in_path
    assert_equal "Please sign in to check in to this event.", flash[:notice]
    assert_equal check_in_path(token), session[:return_to_after_authenticating]
  end

  test "create successfully checks in authenticated user" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    user = users(:three)
    sign_in_as user
    token = CheckIn.token_for_event(event.number)

    assert_difference "CheckIn.count", 1 do
      post check_in_url(token)
    end

    assert_redirected_to user_path
    assert_match(/Successfully checked in/, flash[:notice])

    check_in = event.check_ins.find_by(user: user)
    assert_not_nil check_in
    assert_equal user, check_in.user
  end

  test "create prevents duplicate check-in by same user" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    user = users(:one)
    sign_in_as user
    CheckIn.create!(user: user, event: event, checked_in_at: Time.current)
    token = CheckIn.token_for_event(event.number)

    assert_no_difference "CheckIn.count" do
      post check_in_url(token)
    end

    assert_redirected_to user_path
    assert_match(/Could not check in/, flash[:alert])
  end

  test "create redirects when no active event" do
    sign_in_as users(:one)
    token = CheckIn.token_for_event(999)

    post check_in_url(token)

    assert_redirected_to root_path
    assert_equal "No active event for check-in.", flash[:alert]
  end

  test "create returns error for invalid token" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    sign_in_as users(:one)

    assert_raises(ActionController::UrlGenerationError) do
      post check_in_url("invalidtoken")
    end
  end

  test "create handles race condition when trying to check in twice" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    user = users(:one)
    sign_in_as user
    token = CheckIn.token_for_event(event.number)

    CheckIn.create!(user: user, event: event, checked_in_at: Time.current)

    assert_no_difference "CheckIn.count" do
      post check_in_url(token)
    end

    assert_redirected_to user_path
    assert_match(/Could not check in/, flash[:alert])
  end

  test "create allows different users to check in to same event" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    user1 = users(:one)
    user2 = users(:two)
    token = CheckIn.token_for_event(event.number)

    sign_in_as user1
    post check_in_url(token)
    delete sign_out_url

    sign_in_as user2
    assert_difference "CheckIn.count", 1 do
      post check_in_url(token)
    end

    assert_redirected_to user_path
    assert_match(/Successfully checked in/, flash[:notice])
  end

  test "create works when user already has a finish position" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    user = users(:one)
    sign_in_as user
    event.finish_positions.create!(user: user, position: 1)
    token = CheckIn.token_for_event(event.number)

    assert_difference "CheckIn.count", 1 do
      post check_in_url(token)
    end

    assert_redirected_to user_path
    assert_match(/Successfully checked in/, flash[:notice])
  end
end
