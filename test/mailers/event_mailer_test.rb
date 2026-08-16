require "test_helper"

class EventMailerTest < ActionMailer::TestCase
  test "volunteer_notification is addressed to the volunteer" do
    volunteer = volunteers(:one)

    email = EventMailer.volunteer_notification(volunteer: volunteer)

    assert_equal [ volunteer.user.email_address ], email.to
  end

  test "volunteer_notification subject names the event number and location" do
    volunteer = volunteers(:one)

    email = EventMailer.volunteer_notification(volunteer: volunteer)

    assert_equal "Thank you for volunteering at WS10 ##{volunteer.event.number} at #{volunteer.event.location}", email.subject
  end

  test "volunteer_notification body thanks the volunteer by name and role" do
    volunteer = volunteers(:one)

    email = EventMailer.volunteer_notification(volunteer: volunteer)

    assert_includes email.html_part.body.to_s, volunteer.user.name
    assert_includes email.html_part.body.to_s, volunteer.role
    assert_includes email.text_part.body.to_s, volunteer.user.name
    assert_includes email.text_part.body.to_s, volunteer.role
  end

  test "volunteer_notification counts how many times the user has volunteered" do
    event = events(:draft_event)
    user = users(:one)
    user.volunteers.destroy_all
    Volunteer.create!(event: events(:one), user: user, role: "Marshal")
    volunteer = Volunteer.create!(event: event, user: user, role: "Timer")

    email = EventMailer.volunteer_notification(volunteer: volunteer.reload)

    assert_includes email.html_part.body.to_s, "2nd time volunteering"
  end

  test "volunteer_notification counts volunteering at this location" do
    location = locations(:bungarribee)
    user = users(:one)
    user.volunteers.destroy_all
    Volunteer.create!(event: events(:one), user: user, role: "Marshal")
    event = Event.create!(number: 900, date: Date.current, location: location)
    volunteer = Volunteer.create!(event: event, user: user, role: "Timer")

    email = EventMailer.volunteer_notification(volunteer: volunteer.reload)

    assert_includes email.html_part.body.to_s, "2nd time at #{location}"
  end

  test "volunteer_notification welcomes a first time volunteer with no results" do
    user = users(:three)
    user.results.destroy_all
    user.volunteers.destroy_all
    volunteer = Volunteer.create!(event: events(:draft_event), user: user, role: "Timer")

    email = EventMailer.volunteer_notification(volunteer: volunteer.reload)

    assert_includes email.html_part.body.to_s, "This was your first WS10 event"
  end

  test "volunteer_notification does not welcome a returning volunteer" do
    user = users(:one)
    user.volunteers.destroy_all
    Volunteer.create!(event: events(:one), user: user, role: "Marshal")
    volunteer = Volunteer.create!(event: events(:draft_event), user: user, role: "Timer")

    email = EventMailer.volunteer_notification(volunteer: volunteer.reload)

    assert_not_includes email.html_part.body.to_s, "This was your first WS10 event"
  end

  test "volunteer_notification reports total events, runs and volunteer roles" do
    user = users(:one)
    user.results.destroy_all
    user.volunteers.destroy_all
    Result.create!(event: events(:one), user: user, time: 1800)
    Result.create!(event: events(:two), user: user)
    volunteer = Volunteer.create!(event: events(:draft_event), user: user, role: "Timer")

    email = EventMailer.volunteer_notification(volunteer: volunteer.reload)
    body = email.html_part.body.to_s

    assert_includes body, "Total Events"
    assert_includes body, "Runs Completed"
    assert_includes body, "Volunteer Roles"
  end

  test "volunteer_notification sends both html and text parts" do
    volunteer = volunteers(:one)

    email = EventMailer.volunteer_notification(volunteer: volunteer)

    assert email.multipart?
    assert_not_nil email.html_part
    assert_not_nil email.text_part
  end
end
