require "test_helper"

class EventMailerTest < ActionMailer::TestCase
  test "result_notification email" do
    event = events(:one)
    event.update!(status: "finalised", description: "Great event today!")
    result = results(:one)
    result.update!(time: 1600)

    email = EventMailer.result_notification(result: result)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ["matt@ws10.run"], email.from
    assert_equal [result.user.email_address], email.to
    assert_equal "Your result for WS10 ##{event.number} at #{event.location}", email.subject
    assert_match result.user.name, email.html_part.body.to_s
    assert_match result.time_string, email.html_part.body.to_s
  end

  test "result_notification includes event description" do
    event = events(:one)
    event.update!(status: "finalised", description: "Special event description")
    result = results(:one)
    result.update!(time: 1600)

    email = EventMailer.result_notification(result: result)

    assert_match "Special event description", email.html_part.body.to_s
  end

  test "result_notification without event description" do
    event = events(:one)
    event.update!(status: "finalised", description: nil)
    result = results(:one)
    result.update!(time: 1600)

    email = EventMailer.result_notification(result: result)

    assert_not_nil email
    assert_emails 1 do
      email.deliver_now
    end
  end

  test "participation_notification email" do
    event = events(:one)
    event.update!(status: "finalised")
    result = results(:one)
    result.update!(time: nil)

    email = EventMailer.participation_notification(result: result)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ["matt@ws10.run"], email.from
    assert_equal [result.user.email_address], email.to
    assert_equal "You participated in WS10 ##{event.number} at #{event.location}", email.subject
    assert_match result.user.name, email.html_part.body.to_s
  end

  test "participation_notification includes event description" do
    event = events(:one)
    event.update!(status: "finalised", description: "Wet and muddy conditions")
    result = results(:one)
    result.update!(time: nil)

    email = EventMailer.participation_notification(result: result)

    assert_match "Wet and muddy conditions", email.html_part.body.to_s
  end

  test "volunteer_thank_you email" do
    event = events(:one)
    event.update!(status: "finalised")
    volunteer = volunteers(:one)

    email = EventMailer.volunteer_thank_you(volunteer: volunteer)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ["matt@ws10.run"], email.from
    assert_equal [volunteer.user.email_address], email.to
    assert_equal "Thank you for volunteering at WS10 ##{event.number}", email.subject
    assert_match volunteer.user.name, email.html_part.body.to_s
    assert_match volunteer.role, email.html_part.body.to_s
  end

  test "volunteer_thank_you includes volunteer count" do
    event = events(:one)
    event.update!(status: "finalised")
    volunteer = volunteers(:one)

    email = EventMailer.volunteer_thank_you(volunteer: volunteer)

    assert_match /\d+(st|nd|rd|th) time volunteering/, email.html_part.body.to_s
  end
end
