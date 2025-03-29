require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "can create a user" do
    user = User.new(email_address: "you@example.com", name: "You", password: "test-password-123")
    assert user.valid?
  end

  test "first fixture is valid" do
    # Seems unnecessary but subsequent tests depend on this and it picked up an unwanted validation
    assert users(:one).valid?
  end

  test "email address can't be blank" do
    user = users(:one)
    user.email_address = nil
    assert_not user.valid?
  end

  test "email address can't be blank in database" do
    user = users(:one)
    user.email_address = nil
    assert_raises(ActiveRecord::NotNullViolation) { user.save(validate: false) }
  end

  test "name can't be blank" do
    user = users(:one)
    user.name = nil
    assert_not user.valid?
  end

  test "name can't be blank in database" do
    user = users(:one)
    user.name = nil
    assert_raises(ActiveRecord::NotNullViolation) { user.save(validate: false) }
  end

  test "password can't be blank" do
    user = users(:one)
    user.password = nil
    assert_not user.valid?
  end

  test "password (digest) can't be blank in database" do
    user = users(:one)
    user.password = nil
    assert_raises(ActiveRecord::NotNullViolation) { user.save(validate: false) }
  end

  test "user defaults are set using values in schema" do
    minimum_viable_user = User.create(email_address: "you@example.com", name: "You", password: "test-password-123")
    assert minimum_viable_user.display_name = "Anonymous"
    assert minimum_viable_user.emoji = "👤"
  end
end
