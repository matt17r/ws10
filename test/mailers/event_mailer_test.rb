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

  %i[result_notification participation_notification].each do |mail_type|
    test "#{mail_type} does not ask for financial support from regular runners" do
      result = results(:first)
      Result.create!(event: events(:two), user: result.user, time: 2_600)
      Result.create!(event: events(:draft_event), user: result.user, time: 2_700)

      email = EventMailer.public_send(mail_type, result: result)

      assert_no_match(%r{/support}, email.html_part.body.to_s)
      assert_no_match(%r{/support}, email.text_part.body.to_s)
      assert_no_match(/supporting WS10/i, email.html_part.body.to_s)
      assert_no_match(/supporting WS10/i, email.text_part.body.to_s)
    end
  end

  %i[result_notification participation_notification].each do |mail_type|
    test "#{mail_type} includes the event description in both parts" do
      result = results(:first)
      result.event.update!(description: "Muggy conditions and a new course record")

      email = EventMailer.public_send(mail_type, result: result)

      assert_includes email.html_part.body.to_s, "Muggy conditions and a new course record"
      assert_includes email.text_part.body.to_s, "Muggy conditions and a new course record"
    end

    test "#{mail_type} omits the description block when the event has none" do
      result = results(:first)
      result.event.update!(description: "")

      email = EventMailer.public_send(mail_type, result: result)

      assert_no_match(/border-left: 4px solid #DB2955/, email.html_part.body.to_s)
      assert email.text_part.body.to_s.present?
    end
  end

  test "volunteer_notification includes the event description in both parts" do
    volunteer = volunteers(:one)
    volunteer.event.update!(description: "Muggy conditions and a new course record")

    email = EventMailer.volunteer_notification(volunteer: volunteer)

    assert_includes email.html_part.body.to_s, "Muggy conditions and a new course record"
    assert_includes email.text_part.body.to_s, "Muggy conditions and a new course record"
  end

  %i[result_notification participation_notification].each do |mail_type|
    test "#{mail_type} does not invite the runner to a future event" do
      result = results(:first)

      email = EventMailer.public_send(mail_type, result: result)

      [ email.html_part.body.to_s, email.text_part.body.to_s ].each do |body|
        assert_no_match(/next event/i, body)
        assert_no_match(%r{/courses}, body)
        assert_no_match(/young event/i, body)
        assert_no_match(/still learning/i, body)
      end
    end

    test "#{mail_type} thanks the runner for being part of WS10" do
      result = results(:first)

      email = EventMailer.public_send(mail_type, result: result)

      assert_includes email.html_part.body.to_s, "Thank you for being part of Western Sydney 10"
      assert_includes email.text_part.body.to_s, "Thank you for being part of Western Sydney 10"
    end
  end
end
