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
  end

  test "destroy removes check-in when admin" do
    event = events(:draft_event)
    user = users(:three)
    admin = users(:one)
    check_in = CheckIn.create!(user: user, event: event, checked_in_at: Time.current)
    sign_in_as admin

    assert_difference "CheckIn.count", -1 do
      delete admin_check_in_url(check_in)
    end

    assert_redirected_to event_path(event.number)
    assert_match(/Check-in removed for #{user.name}/, flash[:notice])
  end

  test "destroy requires admin authentication" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.create!(user: user, event: event, checked_in_at: Time.current)
    sign_in_as user

    assert_no_difference "CheckIn.count" do
      delete admin_check_in_url(check_in)
    end

    assert_response :not_found
  end

  test "destroy redirects for non-existent check-in" do
    admin = users(:one)
    sign_in_as admin

    delete admin_check_in_url(id: 99999)

    assert_redirected_to dashboard_path
    assert_equal "Check-in not found.", flash[:alert]
  end

  test "user can delete their own check-in via user route" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    user = users(:three)
    sign_in_as user
    check_in = CheckIn.create!(user: user, event: event, checked_in_at: Time.current)

    assert_difference "CheckIn.count", -1 do
      delete user_check_in_url(check_in)
    end

    assert_redirected_to courses_path
    assert_equal "Check-in cancelled.", flash[:notice]
  end

  test "user cannot delete another user's check-in" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    user1 = users(:three)
    user2 = users(:two)
    check_in = CheckIn.create!(user: user1, event: event, checked_in_at: Time.current)
    sign_in_as user2

    assert_no_difference "CheckIn.count" do
      delete user_check_in_url(check_in)
    end

    assert_redirected_to user_path
    assert_equal "You can only cancel your own check-in.", flash[:alert]
  end

  test "unauthenticated user cannot delete check-in via user route" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.create!(user: user, event: event, checked_in_at: Time.current)

    assert_no_difference "CheckIn.count" do
      delete user_check_in_url(check_in)
    end

    assert_redirected_to sign_in_path
  end

  test "admin can delete any check-in via user route" do
    event = events(:draft_event)
    user = users(:three)
    admin = users(:one)
    check_in = CheckIn.create!(user: user, event: event, checked_in_at: Time.current)
    sign_in_as admin

    assert_difference "CheckIn.count", -1 do
      delete user_check_in_url(check_in)
    end

    assert_redirected_to event_path(event.number)
    assert_match(/Check-in removed for #{user.name}/, flash[:notice])
  end

  test "user route redirects to user_path for non-existent check-in" do
    user = users(:three)
    sign_in_as user

    delete user_check_in_url(id: 99999)

    assert_redirected_to user_path
    assert_equal "Check-in not found.", flash[:alert]
  end

  test "create_for_friend requires authentication" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    token = CheckIn.token_for_event(event.number)

    post check_in_friend_url(token), params: { barcode: "A000001" }

    assert_redirected_to sign_in_path
  end

  test "create_for_friend requires current user to be checked in first" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    user = users(:one)
    friend = users(:three)
    sign_in_as user
    token = CheckIn.token_for_event(event.number)

    post check_in_friend_url(token), params: { barcode: friend.barcode_string }

    assert_redirected_to check_in_path(token)
    assert_match(/check yourself in first/i, flash[:alert])
  end

  test "create_for_friend successfully checks in friend" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    user = users(:one)
    friend = users(:three)
    sign_in_as user
    CheckIn.create!(user: user, event: event, checked_in_at: Time.current)
    token = CheckIn.token_for_event(event.number)

    assert_difference "CheckIn.count", 1 do
      post check_in_friend_url(token), params: { barcode: friend.barcode_string }
    end

    assert_redirected_to check_in_path(token)
    assert event.check_ins.exists?(user: friend)
  end

  test "create_for_friend redirects back to check-in page after success" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    user = users(:one)
    friend = users(:three)
    sign_in_as user
    CheckIn.create!(user: user, event: event, checked_in_at: Time.current)
    token = CheckIn.token_for_event(event.number)

    post check_in_friend_url(token), params: { barcode: friend.barcode_string }

    assert_redirected_to check_in_path(token)
  end

  test "create_for_friend shows error for invalid barcode" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    user = users(:one)
    sign_in_as user
    CheckIn.create!(user: user, event: event, checked_in_at: Time.current)
    token = CheckIn.token_for_event(event.number)

    post check_in_friend_url(token), params: { barcode: "invalid" }

    assert_redirected_to check_in_path(token)
    assert_match(/No user found/i, flash[:alert])
  end

  test "create_for_friend shows error when friend already checked in" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    user = users(:one)
    friend = users(:three)
    sign_in_as user
    CheckIn.create!(user: user, event: event, checked_in_at: Time.current)
    CheckIn.create!(user: friend, event: event, checked_in_at: Time.current)
    token = CheckIn.token_for_event(event.number)

    assert_no_difference "CheckIn.count" do
      post check_in_friend_url(token), params: { barcode: friend.barcode_string }
    end

    assert_redirected_to check_in_path(token)
    assert_match(/Could not check in/i, flash[:alert])
  end

  test "create_for_friend accepts lowercase barcode" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    user = users(:one)
    friend = users(:three)
    sign_in_as user
    CheckIn.create!(user: user, event: event, checked_in_at: Time.current)
    token = CheckIn.token_for_event(event.number)

    assert_difference "CheckIn.count", 1 do
      post check_in_friend_url(token), params: { barcode: friend.barcode_string.downcase }
    end

    assert event.check_ins.exists?(user: friend)
  end

  test "create_for_friend redirects when no active event" do
    user = users(:one)
    sign_in_as user
    token = CheckIn.token_for_event(999)

    post check_in_friend_url(token), params: { barcode: "A000001" }

    assert_redirected_to root_path
    assert_equal "No active event for check-in.", flash[:alert]
  end
end
