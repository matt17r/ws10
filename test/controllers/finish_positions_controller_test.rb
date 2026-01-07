require "test_helper"

class FinishPositionsControllerTest < ActionDispatch::IntegrationTest
  test "new_user shows form for creating user" do
    sign_in_as users(:one)
    event = events(:draft_event)
    finish_position = FinishPosition.create!(event: event, position: 1)

    get new_user_finish_position_path(finish_position)

    assert_response :success
    assert_select "h1", text: "Quick add user for position #1"
  end

  test "create_user creates user and links to finish position" do
    sign_in_as users(:one)
    event = events(:draft_event)
    finish_position = FinishPosition.create!(event: event, position: 1)

    assert_difference "User.count", 1 do
      post create_user_finish_position_path(finish_position), params: {
        user: {
          name: "New Runner",
          display_name: "NR",
          email_address: "newrunner@example.com"
        }
      }
    end

    assert_redirected_to dashboard_path
    assert_match(/New Runner created and placed at #1/, flash[:notice])

    finish_position.reload
    assert_not_nil finish_position.user
    assert_equal "New Runner", finish_position.user.name
    assert_equal "NR", finish_position.user.display_name
    assert_equal "newrunner@example.com", finish_position.user.email_address
    assert_equal "👤", finish_position.user.emoji
  end

  test "create_user shows errors for invalid data" do
    sign_in_as users(:one)
    event = events(:draft_event)
    finish_position = FinishPosition.create!(event: event, position: 1)

    assert_no_difference "User.count" do
      post create_user_finish_position_path(finish_position), params: {
        user: {
          name: "",
          display_name: "NR",
          email_address: "invalid"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create_user shows error for duplicate email" do
    sign_in_as users(:one)
    event = events(:draft_event)
    finish_position = FinishPosition.create!(event: event, position: 1)
    existing_user = users(:one)

    assert_no_difference "User.count" do
      post create_user_finish_position_path(finish_position), params: {
        user: {
          name: "New Runner",
          display_name: "NR",
          email_address: existing_user.email_address
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "new_user requires admin authentication" do
    event = events(:draft_event)
    finish_position = FinishPosition.create!(event: event, position: 1)

    get new_user_finish_position_path(finish_position)

    assert_response :not_found
  end

  test "create_user requires admin authentication" do
    event = events(:draft_event)
    finish_position = FinishPosition.create!(event: event, position: 1)

    assert_no_difference "User.count" do
      post create_user_finish_position_path(finish_position), params: {
        user: {
          name: "New Runner",
          display_name: "NR",
          email_address: "newrunner@example.com"
        }
      }
    end

    assert_response :not_found
  end

  test "show_claim displays unclaimed position" do
    event = events(:draft_event)
    event.update!(status: 'in_progress')
    prefix = FinishPosition.token_prefix_for_position(1)

    get claim_finish_token_url(prefix, "001")
    assert_response :success
    assert_select "h3", text: "Position #1"
  end

  test "show_claim shows claimer name if position already claimed" do
    event = events(:draft_event)
    event.update!(status: 'in_progress')
    claimer = users(:three)
    event.finish_positions.create!(user: claimer, position: 1)
    prefix = FinishPosition.token_prefix_for_position(1)

    get claim_finish_token_url(prefix, "001")
    assert_response :success
    assert_select "p", text: "This position has already been claimed by:"
    assert_select "span", text: claimer.display_name
    assert_select "form", count: 0
  end

  test "show_claim returns 404 for invalid token" do
    event = events(:draft_event)
    event.update!(status: 'in_progress')

    get claim_finish_token_url("abcd", "001")
    assert_response :not_found
  end

  test "claim redirects to sign in when not authenticated" do
    event = events(:draft_event)
    event.update!(status: 'in_progress')
    prefix = FinishPosition.token_prefix_for_position(1)

    post claim_finish_token_url(prefix, "001")
    assert_redirected_to sign_in_path
    assert_equal "Please sign in to claim your finish position.", flash[:notice]
  end

  test "claim creates finish position when authenticated" do
    event = events(:draft_event)
    event.update!(status: 'in_progress')
    user = users(:three)
    sign_in_as user
    prefix = FinishPosition.token_prefix_for_position(1)

    assert_difference "FinishPosition.count", 1 do
      post claim_finish_token_url(prefix, "001")
    end

    assert_redirected_to user_path
    assert_equal "Successfully claimed position #1!", flash[:notice]

    finish_position = event.finish_positions.find_by(position: 1)
    assert_equal user, finish_position.user
  end

  test "claim prevents duplicate claims by same user" do
    event = events(:draft_event)
    event.update!(status: 'in_progress')
    user = users(:three)
    sign_in_as user
    event.finish_positions.create!(user: user, position: 2)
    prefix = FinishPosition.token_prefix_for_position(1)

    post claim_finish_token_url(prefix, "001")

    assert_redirected_to user_path
    assert_match /Could not claim position/, flash[:alert]
  end

  test "claim handles race condition when position already claimed" do
    event = events(:draft_event)
    event.update!(status: 'in_progress')
    user = users(:three)
    sign_in_as user
    event.finish_positions.create!(user: users(:one), position: 1)
    prefix = FinishPosition.token_prefix_for_position(1)

    post claim_finish_token_url(prefix, "001")

    assert_redirected_to user_path
    assert_match /Could not claim position/, flash[:alert]
  end
end
