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

  test "thanks_notification is addressed to the runner" do
    result = Result.create!(event: events(:draft_event), user: users(:three))

    email = EventMailer.thanks_notification(result: result)

    assert_equal [ users(:three).email_address ], email.to
  end

  test "thanks_notification subject thanks the runner for coming" do
    event = events(:draft_event)
    result = Result.create!(event: event, user: users(:three))

    email = EventMailer.thanks_notification(result: result)

    assert_equal "Thanks for coming to WS10 ##{event.number} at #{event.location}", email.subject
  end

  test "thanks_notification shows the runner's time when they recorded one" do
    result = Result.create!(event: events(:draft_event), user: users(:three), time: 52 * 60 + 25)

    email = EventMailer.thanks_notification(result: result)

    assert_includes email.html_part.body.to_s, "52:25"
    assert_includes email.text_part.body.to_s, "52:25"
    assert_not_includes email.text_part.body.to_s, "Add your time"
  end

  test "thanks_notification invites runners without a time to add one" do
    result = Result.create!(event: events(:draft_event), user: users(:three))

    email = EventMailer.thanks_notification(result: result)

    assert_includes email.html_part.body.to_s, "/checkin"
    assert_includes email.text_part.body.to_s, "Add your time"
    assert_includes email.text_part.body.to_s, "/checkin"
  end

  test "thanks_notification does not mention finishing places" do
    result = Result.create!(event: events(:draft_event), user: users(:three), time: 52 * 60 + 25)

    email = EventMailer.thanks_notification(result: result)

    assert_not_includes email.text_part.body.to_s, "place"
    assert_not_includes email.html_part.body.to_s, "place out of"
  end

  test "thanks_notification names the next event" do
    result = Result.create!(event: events(:draft_event), user: users(:three))
    next_event = Event.create!(number: 4, date: Date.new(2025, 6, 15), location: locations(:bungarribee))

    email = travel_to(events(:draft_event).check_in_closes_at + 9.hours) do
      EventMailer.thanks_notification(result: result).tap(&:deliver_now)
    end

    assert_includes email.text_part.body.to_s, "##{next_event.number} at #{next_event.location} on Sunday 15 June"
    assert_includes email.html_part.body.to_s, "Sunday 15 June"
  end

  test "thanks_notification sends both html and text parts" do
    result = Result.create!(event: events(:draft_event), user: users(:three))

    email = EventMailer.thanks_notification(result: result)

    assert_equal 2, email.parts.size
  end
end
