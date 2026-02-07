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

  test "find_by_barcode returns user for valid barcode" do
    user = users(:one)

    found = User.find_by_barcode(user.barcode_string)

    assert_equal user, found
  end

  test "find_by_barcode is case insensitive" do
    user = users(:one)

    found = User.find_by_barcode(user.barcode_string.downcase)

    assert_equal user, found
  end

  test "find_by_barcode returns nil for invalid format" do
    assert_nil User.find_by_barcode("B000001")
    assert_nil User.find_by_barcode("invalid")
    assert_nil User.find_by_barcode("")
    assert_nil User.find_by_barcode(nil)
  end

  test "find_by_barcode returns nil for non-existent user" do
    assert_nil User.find_by_barcode("A999999")
  end

  test "find_by_barcode accepts digits only" do
    user = users(:one)

    found = User.find_by_barcode(user.id.to_s)

    assert_equal user, found
  end

  test "find_by_barcode accepts digits with leading zeros" do
    user = users(:one)

    found = User.find_by_barcode(sprintf("%06d", user.id))

    assert_equal user, found
  end

  test "find_by_barcode! raises RecordNotFound for invalid barcode" do
    assert_raises(ActiveRecord::RecordNotFound) do
      User.find_by_barcode!("invalid")
    end
  end

  test "find_by_barcode! raises RecordNotFound for non-existent user" do
    assert_raises(ActiveRecord::RecordNotFound) do
      User.find_by_barcode!("A999999")
    end
  end

  test "never_confirmed scope returns users not confirmed after 30+ days" do
    old_unconfirmed_user = User.create!(
      email_address: "old_unconfirmed@example.com",
      name: "Old Unconfirmed",
      password: "password123",
      created_at: 31.days.ago,
      confirmed_at: nil
    )

    recent_unconfirmed_user = User.create!(
      email_address: "recent_unconfirmed@example.com",
      name: "Recent Unconfirmed",
      password: "password123",
      created_at: 29.days.ago,
      confirmed_at: nil
    )

    confirmed_user = User.create!(
      email_address: "confirmed@example.com",
      name: "Confirmed",
      password: "password123",
      created_at: 31.days.ago,
      confirmed_at: 30.days.ago
    )

    never_confirmed_users = User.never_confirmed

    assert_includes never_confirmed_users, old_unconfirmed_user
    assert_not_includes never_confirmed_users, recent_unconfirmed_user
    assert_not_includes never_confirmed_users, confirmed_user
  end

  test "confirmed_but_inactive scope returns confirmed users with no activity in 12+ months" do
    location = locations(:bungarribee)

    inactive_user = User.create!(
      email_address: "inactive@example.com",
      name: "Inactive User",
      password: "password123",
      confirmed_at: 13.months.ago
    )

    active_user = User.create!(
      email_address: "active@example.com",
      name: "Active User",
      password: "password123",
      confirmed_at: 13.months.ago
    )

    recent_event = Event.create!(date: 1.month.ago, location: location, number: 200, status: "finalised")
    Result.create!(user: active_user, event: recent_event, time: 2000)

    unconfirmed_user = User.create!(
      email_address: "unconfirmed@example.com",
      name: "Unconfirmed",
      password: "password123",
      confirmed_at: nil,
      created_at: 13.months.ago
    )

    confirmed_but_inactive_users = User.confirmed_but_inactive

    assert_includes confirmed_but_inactive_users, inactive_user
    assert_not_includes confirmed_but_inactive_users, active_user
    assert_not_includes confirmed_but_inactive_users, unconfirmed_user
  end

  test "confirmed_but_inactive scope excludes users with volunteer activity in past 12 months" do
    location = locations(:bungarribee)

    inactive_user = User.create!(
      email_address: "volunteer@example.com",
      name: "Volunteer User",
      password: "password123",
      confirmed_at: 13.months.ago
    )

    recent_event = Event.create!(date: 1.month.ago, location: location, number: 201, status: "finalised")
    Volunteer.create!(user: inactive_user, event: recent_event)

    confirmed_but_inactive_users = User.confirmed_but_inactive

    assert_not_includes confirmed_but_inactive_users, inactive_user
  end

  test "confirmed_but_inactive scope excludes users with check-in activity in past 12 months" do
    location = locations(:bungarribee)

    inactive_user = User.create!(
      email_address: "checkin@example.com",
      name: "CheckIn User",
      password: "password123",
      confirmed_at: 13.months.ago
    )

    recent_event = Event.create!(date: 1.month.ago, location: location, number: 202, status: "finalised")
    CheckIn.create!(user: inactive_user, event: recent_event, checked_in_at: 1.month.ago)

    confirmed_but_inactive_users = User.confirmed_but_inactive

    assert_not_includes confirmed_but_inactive_users, inactive_user
  end
end
