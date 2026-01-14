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

  test "user has many finish positions" do
    user = users(:one)
    event = events(:draft_event)
    finish_position = FinishPosition.create!(user: user, event: event, position: 1)

    assert_includes user.finish_positions, finish_position
  end

  test "destroying user destroys their finish positions" do
    user = users(:one)
    event = events(:draft_event)
    FinishPosition.create!(user: user, event: event, position: 1)

    assert_difference "FinishPosition.count", -1 do
      user.destroy
    end
  end

  test "confirmed? returns true when user is confirmed" do
    user = users(:one)
    user.update!(confirmed_at: Time.current)

    assert user.confirmed?
  end

  test "confirmed? returns false when user is not confirmed" do
    user = users(:one)
    user.update!(confirmed_at: nil)

    assert_not user.confirmed?
  end

  test "confirm! sets confirmed_at to current time" do
    user = users(:one)
    user.update!(confirmed_at: nil)

    assert_nil user.confirmed_at
    user.confirm!
    assert_not_nil user.confirmed_at
  end

  test "confirm! returns true if already confirmed" do
    user = users(:one)
    user.update!(confirmed_at: 1.day.ago)

    assert user.confirm!
    assert user.confirmed_at <= 1.day.ago
  end

  test "admin? returns true when user has Administrator role" do
    user = users(:one)
    admin_role = roles(:admin)
    Assignment.create!(user: user, role: admin_role)

    assert user.admin?
  end

  test "admin? returns false when user does not have Administrator role" do
    user = users(:one)
    user.assignments.destroy_all

    assert_not user.admin?
  end

  test "organiser? returns true when user has Organiser role" do
    user = users(:one)
    organiser_role = roles(:organiser)
    Assignment.create!(user: user, role: organiser_role)

    assert user.organiser?
  end

  test "organiser? returns false when user does not have Organiser role" do
    user = users(:one)
    user.assignments.destroy_all

    assert_not user.organiser?
  end

  test "personal_best returns fastest result" do
    user = users(:one)
    user.results.destroy_all
    location = locations(:bungarribee)

    event1 = Event.create!(date: Date.today, location: location, number: 100, status: "finalised")
    event2 = Event.create!(date: Date.today + 1.day, location: location, number: 101, status: "finalised")

    result1 = Result.create!(user: user, event: event1, time: 2000)
    result2 = Result.create!(user: user, event: event2, time: 1800)

    assert_equal result2, user.personal_best
  end

  test "personal_best returns nil when user has no timed results" do
    user = users(:one)
    user.results.destroy_all

    assert_nil user.personal_best
  end

  test "barcode_string returns formatted barcode" do
    user = users(:one)
    expected = "A#{sprintf("%06d", user.id)}"

    assert_equal expected, user.barcode_string
  end

  test "name_with_display_name returns formatted name" do
    user = users(:one)
    user.update!(name: "John Doe", display_name: "Johnny")

    assert_equal "John Doe (Johnny)", user.name_with_display_name
  end

  test "has many check_ins" do
    user = users(:one)
    event = events(:draft_event)

    check_in = user.check_ins.create!(event: event, checked_in_at: Time.current)

    assert_includes user.check_ins, check_in
  end

  test "destroys dependent check_ins when user is destroyed" do
    user = users(:one)
    event = events(:draft_event)
    user.check_ins.create!(event: event, checked_in_at: Time.current)

    assert_difference "CheckIn.count", -1 do
      user.destroy
    end
  end
end
