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
end
