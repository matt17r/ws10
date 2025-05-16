# Preview all emails at http://localhost:3000/rails/mailers/event_mailer
class EventMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/event_mailer/result_notification
  def result_notification
    result = Result.all.sample
    EventMailer.result_notification(result: result)
  end
end
