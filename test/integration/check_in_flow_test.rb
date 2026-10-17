require "test_helper"

class CheckInFlowTest < ActionDispatch::IntegrationTest
  test "complete check-in flow for unauthenticated user" do
    event = events(:draft_event)
    user = users(:three)

    travel_to event.check_in_opens_at + 15.minutes do
      get check_in_url
      assert_response :success

      post check_in_url
      assert_redirected_to sign_in_path

      post sign_in_url, params: { email_address: user.email_address, password: "password" }
      assert_redirected_to check_in_path
      follow_redirect!

      assert_difference [ "CheckIn.count", "Result.count" ], 1 do
        post check_in_url
      end

      assert_redirected_to check_in_path
      follow_redirect!
      assert_select "h2", "You're checked in"
    end
  end

  test "late check-in flow from submission to approval" do
    event = events(:draft_event)
    runner = users(:three)

    travel_to event.check_in_closes_at + 1.hour do
      sign_in_as runner
      post check_in_url
      patch check_in_time_url, params: { time_string: "52:25" }
      follow_redirect!
      assert_select "h2", "Waiting for approval"
      assert_not event.results.exists?(user: runner)
      delete sign_out_url

      sign_in_as users(:one)
      post approve_admin_check_in_url(event.check_ins.find_by!(user: runner))
    end

    assert_equal 52 * 60 + 25, event.results.find_by!(user: runner).time
  end

  test "user can check in to events in consecutive months" do
    first_event = events(:draft_event)
    second_event = Event.create!(number: 4, date: Date.new(2025, 6, 15), location: locations(:bungarribee))
    user = users(:three)
    sign_in_as user

    travel_to first_event.check_in_opens_at + 15.minutes do
      post check_in_url
    end

    travel_to second_event.check_in_opens_at + 15.minutes do
      post check_in_url
    end

    assert first_event.check_ins.find_by!(user: user).approved?
    assert second_event.check_ins.find_by!(user: user).approved?
  end
end
