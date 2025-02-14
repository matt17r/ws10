require "test_helper"

class VolunteerTest < ActiveSupport::TestCase
  test "can create a volunteer" do
    volunteer = Volunteer.new(user: users(:one), event: events(:one), role: "Timer")
    assert volunteer.valid?
  end

  test "volunteer must have an event" do
    volunteer = Volunteer.new(user: users(:one), role: "Timer")
    assert_not volunteer.valid?
  end

  test "volunteer must have a user" do
    volunteer = Volunteer.new(event: events(:one), role: "Timer")
    assert_not volunteer.valid?
  end

  test "volunteer must have a role" do
    volunteer = Volunteer.new(user: users(:one), event: events(:one))
    assert_not volunteer.valid?
  end

  test "volunteer must have an event in database" do
    volunteer = volunteers(:one)
    volunteer.event = nil
    assert_raises(ActiveRecord::NotNullViolation) { volunteer.save(validate: false) }
  end

  test "volunteer must have a user in database" do
    volunteer = volunteers(:one)
    volunteer.user = nil
    assert_raises(ActiveRecord::NotNullViolation) { volunteer.save(validate: false) }
  end

  test "volunteer must have a role in database" do
    volunteer = volunteers(:one)
    volunteer.role = nil
    assert_raises(ActiveRecord::NotNullViolation) { volunteer.save(validate: false) }
  end

  test "adding user volunteer increments volunteer count" do
    user = users(:three)
    assert user.volunteers_count == 1

    Volunteer.create(user: users(:three), event: events(:two), role: "Marshall")

    assert user.volunteers_count == 2
  end
end
