require "test_helper"

class CheckInsControllerTest < ActionDispatch::IntegrationTest
  test "show offers check-in during the event's window" do
    event = events(:draft_event)

    travel_to event.check_in_opens_at + 15.minutes do
      get check_in_url
    end

    assert_response :success
    assert_select "h1", "Check in"
    assert_select "p", text: /#{event.location.name}/
    assert_select "button", "Check in"
    assert_select "input[name=time_string]", count: 0
  end

  test "show tells signed-out runners they'll need to sign in" do
    event = events(:draft_event)

    travel_to event.check_in_opens_at + 15.minutes do
      get check_in_url
    end

    assert_select "p", text: /asked to sign in/
  end

  test "show confirms when the runner is already checked in" do
    event = events(:draft_event)
    user = users(:three)
    CheckIn.check_in!(event: event, user: user)
    sign_in_as user

    travel_to event.check_in_opens_at + 15.minutes do
      get check_in_url
    end

    assert_response :success
    assert_select "h2", "You're checked in"
    assert_select "label", text: "Finished? Add your time"
    assert_select "input[type=submit][value=?]", "Save time"
    assert_select "details", count: 0
    assert_select "label", text: /Check someone else in/
  end

  test "show displays a recorded time with the option to edit it" do
    event = events(:draft_event)
    user = users(:three)
    CheckIn.check_in!(event: event, user: user).record_time!("52:25")
    sign_in_as user

    travel_to event.check_in_opens_at + 2.hours do
      get check_in_url
    end

    assert_select "h2", "All done!"
    assert_select "dt", "Your time"
    assert_select "dd", "52:25"
    assert_select "details summary", text: "Edit time"
    assert_select "details input[name=time_string][value=?]", "52:25"
    assert_select "details input[type=submit][value=?]", "Update time"
  end

  test "show displays the time submitted with a pending late check-in" do
    event = events(:draft_event)
    user = users(:three)
    CheckIn.check_in!(event: event, user: user, status: "pending").record_time!("52:25")
    sign_in_as user

    travel_to event.check_in_closes_at + 1.hour do
      get check_in_url
    end

    assert_select "h2", "Waiting for approval"
    assert_select "dd", "52:25"
  end

  test "show offers a late check-in once the window has closed" do
    event = events(:draft_event)
    sign_in_as users(:three)

    travel_to event.check_in_closes_at + 1.hour do
      get check_in_url
    end

    assert_response :success
    assert_select "p", text: /Check-in for this event closed/
    assert_select "button", "Submit late check-in"
  end

  test "show tells the runner a late check-in is waiting for approval" do
    event = events(:draft_event)
    user = users(:three)
    CheckIn.check_in!(event: event, user: user, status: "pending")
    sign_in_as user

    travel_to event.check_in_closes_at + 1.hour do
      get check_in_url
    end

    assert_select "h2", "Waiting for approval"
  end

  test "show points to the next event when nothing is open" do
    event = events(:one)

    travel_to event.check_in_opens_at - 2.days do
      get check_in_url
    end

    assert_response :success
    assert_select "h2", "Check-in isn't open yet"
    assert_select "p", text: /6:30am/
    assert_select "a[href=?]", course_path(event.location)
  end

  test "show handles there being no events at all" do
    travel_to Time.utc(2020, 1, 1) do
      get check_in_url
    end

    assert_response :success
    assert_select "h2", "Check-in isn't open yet"
  end

  test "old event-specific check-in links redirect to the permanent check-in page" do
    get "/checkin/abcd1234"

    assert_redirected_to check_in_path
  end

  test "create redirects to sign in when not authenticated" do
    event = events(:draft_event)

    travel_to event.check_in_opens_at + 15.minutes do
      post check_in_url
    end

    assert_redirected_to sign_in_path
    assert_equal "Please sign in to check in to this event.", flash[:notice]
    assert_equal check_in_path, session[:return_to_after_authenticating]
  end

  test "create checks the runner in and records them as a participant" do
    event = events(:draft_event)
    user = users(:three)
    sign_in_as user

    assert_difference [ "CheckIn.count", "Result.count" ], 1 do
      travel_to event.check_in_opens_at + 15.minutes do
        post check_in_url
      end
    end

    assert_redirected_to check_in_path
    assert event.check_ins.find_by!(user: user).approved?
    assert_nil event.results.find_by!(user: user).time
  end

  test "create prevents duplicate check-in by same user" do
    event = events(:draft_event)
    user = users(:three)
    CheckIn.check_in!(event: event, user: user)
    sign_in_as user

    assert_no_difference "CheckIn.count" do
      travel_to event.check_in_opens_at + 15.minutes do
        post check_in_url
      end
    end

    assert_redirected_to check_in_path
    assert_match(/Could not check in/, flash[:alert])
  end

  test "create during a manually activated event checks the runner in outside the window" do
    event = events(:draft_event)
    event.update!(status: "in_progress")
    user = users(:three)
    sign_in_as user

    travel_to event.check_in_opens_at - 1.day do
      post check_in_url
    end

    assert event.check_ins.find_by!(user: user).approved?
  end

  test "create after the window closes saves a pending check-in without a result" do
    event = events(:draft_event)
    user = users(:three)
    sign_in_as user

    assert_no_difference "Result.count" do
      travel_to event.check_in_closes_at + 1.hour do
        post check_in_url
      end
    end

    assert event.check_ins.find_by!(user: user).pending?
    assert_redirected_to check_in_path
    assert_match(/approve/, flash[:notice])
  end

  test "create when nothing is open does not check in" do
    event = events(:one)
    sign_in_as users(:three)

    assert_no_difference "CheckIn.count" do
      travel_to event.check_in_opens_at - 2.days do
        post check_in_url
      end
    end

    assert_redirected_to check_in_path
    assert_equal "Check-in isn't open right now.", flash[:alert]
  end

  test "update_time records the time on the runner's result" do
    event = events(:draft_event)
    user = users(:three)
    CheckIn.check_in!(event: event, user: user)
    sign_in_as user

    travel_to event.check_in_opens_at + 2.hours do
      patch check_in_time_url, params: { time_string: "52:25" }
    end

    assert_redirected_to check_in_path
    assert_equal "Time saved: 52:25.", flash[:notice]
    assert_equal 52 * 60 + 25, event.results.find_by!(user: user).time
  end

  test "update_time rejects an invalid time" do
    event = events(:draft_event)
    user = users(:three)
    CheckIn.check_in!(event: event, user: user)
    sign_in_as user

    travel_to event.check_in_opens_at + 2.hours do
      patch check_in_time_url, params: { time_string: "nonsense" }
    end

    assert_redirected_to check_in_path
    assert_match(/Could not save your time: Time string must be a valid time/, flash[:alert])
    assert_nil event.results.find_by!(user: user).time
  end

  test "update_time needs the runner to be checked in first" do
    event = events(:draft_event)
    sign_in_as users(:three)

    travel_to event.check_in_opens_at + 2.hours do
      patch check_in_time_url, params: { time_string: "52:25" }
    end

    assert_redirected_to check_in_path
    assert_equal "Please check in first.", flash[:alert]
    assert_not event.results.exists?(user: users(:three))
  end

  test "update_time requires authentication" do
    event = events(:draft_event)

    travel_to event.check_in_opens_at + 2.hours do
      patch check_in_time_url, params: { time_string: "52:25" }
    end

    assert_redirected_to sign_in_path
  end

  test "update_time after the window closes still updates an approved result" do
    event = events(:draft_event)
    user = users(:three)
    CheckIn.check_in!(event: event, user: user)
    sign_in_as user

    travel_to event.check_in_closes_at + 1.hour do
      patch check_in_time_url, params: { time_string: "52:25" }
    end

    assert_equal 52 * 60 + 25, event.results.find_by!(user: user).time
  end

  test "update_time on a pending late check-in stores the time for approval" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.check_in!(event: event, user: user, status: "pending")
    sign_in_as user

    travel_to event.check_in_closes_at + 1.hour do
      patch check_in_time_url, params: { time_string: "52:25" }
    end

    assert_equal 52 * 60 + 25, check_in.reload.submitted_time
    assert_not event.results.exists?(user: user)
  end

  test "create_for_friend requires authentication" do
    event = events(:draft_event)

    travel_to event.check_in_opens_at + 15.minutes do
      post check_in_friend_url, params: { barcode: "A000001" }
    end

    assert_redirected_to sign_in_path
  end

  test "create_for_friend requires current user to be checked in first" do
    event = events(:draft_event)
    sign_in_as users(:one)

    travel_to event.check_in_opens_at + 15.minutes do
      post check_in_friend_url, params: { barcode: users(:three).barcode_string }
    end

    assert_redirected_to check_in_path
    assert_match(/check yourself in first/i, flash[:alert])
  end

  test "create_for_friend checks the friend in and records them as a participant" do
    event = events(:draft_event)
    user = users(:one)
    friend = users(:three)
    CheckIn.check_in!(event: event, user: user)
    sign_in_as user

    assert_difference [ "CheckIn.count", "Result.count" ], 1 do
      travel_to event.check_in_opens_at + 15.minutes do
        post check_in_friend_url, params: { barcode: friend.barcode_string }
      end
    end

    assert_redirected_to check_in_path
    assert event.check_ins.find_by!(user: friend).approved?
    assert event.results.exists?(user: friend)
  end

  test "create_for_friend after the window closes saves a pending check-in for the friend" do
    event = events(:draft_event)
    user = users(:one)
    friend = users(:three)
    CheckIn.check_in!(event: event, user: user, status: "pending")
    sign_in_as user

    travel_to event.check_in_closes_at + 1.hour do
      post check_in_friend_url, params: { barcode: friend.barcode_string }
    end

    assert event.check_ins.find_by!(user: friend).pending?
    assert_not event.results.exists?(user: friend)
  end

  test "create_for_friend shows error for invalid barcode" do
    event = events(:draft_event)
    user = users(:one)
    CheckIn.check_in!(event: event, user: user)
    sign_in_as user

    travel_to event.check_in_opens_at + 15.minutes do
      post check_in_friend_url, params: { barcode: "invalid" }
    end

    assert_redirected_to check_in_path
    assert_match(/No user found/i, flash[:alert])
  end

  test "create_for_friend shows error when friend already checked in" do
    event = events(:draft_event)
    user = users(:one)
    friend = users(:three)
    CheckIn.check_in!(event: event, user: user)
    CheckIn.check_in!(event: event, user: friend)
    sign_in_as user

    assert_no_difference "CheckIn.count" do
      travel_to event.check_in_opens_at + 15.minutes do
        post check_in_friend_url, params: { barcode: friend.barcode_string }
      end
    end

    assert_redirected_to check_in_path
    assert_match(/Could not check in/i, flash[:alert])
  end

  test "create_for_friend accepts lowercase barcode" do
    event = events(:draft_event)
    user = users(:one)
    friend = users(:three)
    CheckIn.check_in!(event: event, user: user)
    sign_in_as user

    travel_to event.check_in_opens_at + 15.minutes do
      post check_in_friend_url, params: { barcode: friend.barcode_string.downcase }
    end

    assert event.check_ins.exists?(user: friend)
  end

  test "create_for_friend when nothing is open does not check in" do
    event = events(:one)
    sign_in_as users(:one)

    assert_no_difference "CheckIn.count" do
      travel_to event.check_in_opens_at - 2.days do
        post check_in_friend_url, params: { barcode: users(:three).barcode_string }
      end
    end

    assert_redirected_to check_in_path
    assert_equal "Check-in isn't open right now.", flash[:alert]
  end

  test "admin can remove a check-in, which removes the result too" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.check_in!(event: event, user: user)
    sign_in_as users(:one)

    assert_difference [ "CheckIn.count", "Result.count" ], -1 do
      delete admin_check_in_url(check_in)
    end

    assert_redirected_to event_path(event.number)
    assert_match(/Check-in removed for #{user.name}/, flash[:notice])
  end

  test "admin check-in removal requires admin" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.check_in!(event: event, user: user)
    sign_in_as user

    assert_no_difference "CheckIn.count" do
      delete admin_check_in_url(check_in)
    end

    assert_response :not_found
  end

  test "admin check-in removal redirects for non-existent check-in" do
    sign_in_as users(:one)

    delete admin_check_in_url(id: 99999)

    assert_redirected_to dashboard_path
    assert_equal "Check-in not found.", flash[:alert]
  end

  test "admin can approve a pending check-in, which records the result" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.check_in!(event: event, user: user, status: "pending")
    check_in.record_time!("52:25")
    sign_in_as users(:one)

    post approve_admin_check_in_url(check_in)

    assert_redirected_to event_path(event.number)
    assert_match(/Late check-in approved for #{user.name}/, flash[:notice])
    assert check_in.reload.approved?
    assert_equal 52 * 60 + 25, event.results.find_by!(user: user).time
  end

  test "approving a check-in requires admin" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.check_in!(event: event, user: user, status: "pending")
    sign_in_as user

    post approve_admin_check_in_url(check_in)

    assert_response :not_found
    assert check_in.reload.pending?
  end

  test "user can cancel their own check-in while the event is open, which removes the result" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.check_in!(event: event, user: user)
    sign_in_as user

    assert_difference [ "CheckIn.count", "Result.count" ], -1 do
      travel_to event.check_in_opens_at + 15.minutes do
        delete user_check_in_url(check_in)
      end
    end

    assert_redirected_to check_in_path
    assert_equal "Check-in cancelled.", flash[:notice]
  end

  test "user can cancel their own pending late check-in" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.check_in!(event: event, user: user, status: "pending")
    sign_in_as user

    assert_difference "CheckIn.count", -1 do
      travel_to event.check_in_closes_at + 1.day do
        delete user_check_in_url(check_in)
      end
    end

    assert_redirected_to check_in_path
  end

  test "user cannot cancel their own approved check-in once the event has closed" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.check_in!(event: event, user: user)
    sign_in_as user

    assert_no_difference [ "CheckIn.count", "Result.count" ] do
      travel_to event.check_in_closes_at + 1.day do
        delete user_check_in_url(check_in)
      end
    end

    assert_redirected_to user_path
    assert_equal "Check-in can no longer be cancelled.", flash[:alert]
  end

  test "user cannot delete another user's check-in" do
    event = events(:draft_event)
    check_in = CheckIn.check_in!(event: event, user: users(:three))
    sign_in_as users(:two)

    assert_no_difference "CheckIn.count" do
      travel_to event.check_in_opens_at + 15.minutes do
        delete user_check_in_url(check_in)
      end
    end

    assert_redirected_to user_path
    assert_equal "You can only cancel your own check-in.", flash[:alert]
  end

  test "unauthenticated user cannot delete check-in via user route" do
    check_in = CheckIn.check_in!(event: events(:draft_event), user: users(:three))

    assert_no_difference "CheckIn.count" do
      delete user_check_in_url(check_in)
    end

    assert_redirected_to sign_in_path
  end

  test "admin can delete any check-in via user route" do
    event = events(:draft_event)
    user = users(:three)
    check_in = CheckIn.check_in!(event: event, user: user)
    sign_in_as users(:one)

    assert_difference "CheckIn.count", -1 do
      delete user_check_in_url(check_in)
    end

    assert_redirected_to event_path(event.number)
    assert_match(/Check-in removed for #{user.name}/, flash[:notice])
  end

  test "user route redirects to user_path for non-existent check-in" do
    sign_in_as users(:three)

    delete user_check_in_url(id: 99999)

    assert_redirected_to user_path
    assert_equal "Check-in not found.", flash[:alert]
  end
end
