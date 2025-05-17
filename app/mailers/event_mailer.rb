class EventMailer < ApplicationMailer
  default from: email_address_with_name("matt@ws10.run", "Western Sydney 10")

  def result_notification(result:)
    @event = result.event
    @result = result
    @user = result.user
    @result_count = @user.results.count
    @location_count = @user.results.joins(:event).where(events: { location: @event.location }).count

    mail(
      to: email_address_with_name(@user.email_address, @user.name),
      subject: "Your result for WS10 ##{@event.number} at #{@event.location}"
    )
  end

  def participation_notification(result:)
    @event = result.event
    @result = result
    @user = result.user
    @result_count = @user.results.count
    @location_count = @user.results.joins(:event).where(events: { location: @event.location }).count

    mail(
      to: email_address_with_name(@user.email_address, @user.name),
      subject: "You participated in WS10 ##{@event.number} at #{@event.location}"
    )
  end
end
