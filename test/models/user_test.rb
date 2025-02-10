require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "can create a user" do
    user = User.new(email_address: "you@example.com", password: "test-password-123")
    assert user.valid?
  end

  test "username can't be blank" do
    user = User.new(password: "test-password-123")
    assert_not user.valid?
  end

  test "password can't be blank" do
    user = User.new(email_address: "you@example.com")
    assert_not user.valid?
  end
end
