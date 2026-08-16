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

  test "volunteer_notification sends both html and text parts" do
    volunteer = volunteers(:one)

    email = EventMailer.volunteer_notification(volunteer: volunteer)

    assert email.multipart?
    assert_not_nil email.html_part
    assert_not_nil email.text_part
  end
end
