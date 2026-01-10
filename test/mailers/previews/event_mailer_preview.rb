# Preview all emails at http://localhost:3000/rails/mailers/event_mailer
class EventMailerPreview < ActionMailer::Preview
  def result_notification
    result = Result.where.not(time: nil).where.not(user_id: nil).sample
    EventMailer.result_notification(result: result)
  end

  def participation_notification
    result = Result.where(time: nil).where.not(user_id: nil).sample
    EventMailer.participation_notification(result: result)
  end
end
