# Preview all emails at http://localhost:3000/rails/mailers/event_mailer
class EventMailerPreview < ActionMailer::Preview
  def result_notification
    result = Result.where.not(time: nil).sample
    EventMailer.result_notification(result: result)
  end

  def participation_notification
    result = Result.where(time: nil).sample
    EventMailer.participation_notification(result: result)
  end
end
