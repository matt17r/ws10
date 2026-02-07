require "test_helper"

class Admin::UsersCleanupControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:one)
    @admin_role = roles(:admin)
    Assignment.create!(user: @admin_user, role: @admin_role)
    sign_in_as @admin_user
  end

  test "should get index" do
    get admin_users_cleanup_url
    assert_response :success
  end

  test "should list never confirmed users" do
    old_unconfirmed = User.create!(
      email_address: "old_unconfirmed@example.com",
      name: "Old Unconfirmed",
      password: "password123",
      created_at: 31.days.ago,
      confirmed_at: nil
    )

    get admin_users_cleanup_url
    assert_response :success
    assert_select "table", text: /old_unconfirmed@example.com/
  end

  test "should list confirmed but inactive users" do
    inactive_user = User.create!(
      email_address: "inactive@example.com",
      name: "Inactive User",
      password: "password123",
      confirmed_at: 13.months.ago
    )

    get admin_users_cleanup_url
    assert_response :success
    assert_select "table", text: /inactive@example.com/
  end

  test "should send reminder emails to selected users" do
    user1 = User.create!(
      email_address: "user1@example.com",
      name: "User One",
      password: "password123",
      confirmed_at: 13.months.ago
    )

    user2 = User.create!(
      email_address: "user2@example.com",
      name: "User Two",
      password: "password123",
      confirmed_at: 13.months.ago
    )

    assert_enqueued_emails 2 do
      post send_reminders_admin_users_cleanup_index_url, params: { user_ids: [ user1.id, user2.id ] }
    end

    assert_redirected_to admin_users_cleanup_url
    assert_equal "Sent reminder emails to 2 users.", flash[:notice]
  end

  test "should delete selected users" do
    user1 = User.create!(
      email_address: "delete1@example.com",
      name: "Delete One",
      password: "password123",
      confirmed_at: nil,
      created_at: 31.days.ago
    )

    user2 = User.create!(
      email_address: "delete2@example.com",
      name: "Delete Two",
      password: "password123",
      confirmed_at: nil,
      created_at: 31.days.ago
    )

    assert_difference "User.count", -2 do
      delete bulk_delete_admin_users_cleanup_index_url, params: { user_ids: [ user1.id, user2.id ] }
    end

    assert_redirected_to admin_users_cleanup_url
    assert_equal "Deleted 2 users.", flash[:notice]
  end

  test "should require admin authentication" do
    sign_out
    get admin_users_cleanup_url
    assert_redirected_to root_path
    assert_equal "You must be an admin to access that page.", flash[:alert]
  end

  test "should handle no user selection for reminder emails" do
    post send_reminders_admin_users_cleanup_index_url, params: { user_ids: [] }
    assert_redirected_to admin_users_cleanup_url
    assert_equal "No users selected.", flash[:alert]
  end

  test "should handle no user selection for deletion" do
    delete bulk_delete_admin_users_cleanup_index_url, params: { user_ids: [] }
    assert_redirected_to admin_users_cleanup_url
    assert_equal "No users selected.", flash[:alert]
  end

  private

  def sign_out
    delete sign_out_url
  end
end
