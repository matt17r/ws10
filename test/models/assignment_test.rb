require "test_helper"

class AssignmentTest < ActiveSupport::TestCase
  test "can assign a user to a role" do
    user = users(:one)
    role = roles(:organiser)

    assert_not user.organiser?

    user.roles << role

    assert user.organiser?
  end

  test "deleting a user deletes their role assignment" do
    user = users(:one)

    initial_assignment_count = Assignment.count
    user_role_count = user.roles.count

    user.destroy

    assert user_role_count > 0
    assert Assignment.count == initial_assignment_count - user_role_count
  end

  test "deleting a role deletes user role assignments" do
    role = roles(:organiser)

    initial_assignment_count = Assignment.count
    user_role_count = role.users.count

    role.destroy

    assert user_role_count > 0
    assert Assignment.count == initial_assignment_count - user_role_count
  end
end
