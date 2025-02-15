require "test_helper"

class RoleTest < ActiveSupport::TestCase
  test "can create a role with a unique name" do
    role = Role.new(name: "Supreme Emperor")
    assert role.valid?
  end

  test "can't create a role with an existing name" do
    existing_name = roles(:organiser).name
    role = Role.new(name: existing_name)
    assert_not role.valid?
  end

  test "database doesn't allow duplicate name" do
    existing_name = roles(:organiser).name
    role = Role.new(name: existing_name)
    assert_raises(ActiveRecord::RecordNotUnique) { role.save(validate: false) }
  end
end
