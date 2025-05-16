class EventMailer < ApplicationMailer
  default from: "matt@ws10.run"
  def result_notification(result:)
    @event  = result.event
    @result = result
    @user = result.user
    @result_count = @user.results.count
    @location_count = @user.results.joins(:event).where(events: { location: @event.location }).count

    mail(
      to:      @user.email_address,
      subject: "Your result for WS10 ##{@event.number} at #{@event.location}"
    )
  end
end
