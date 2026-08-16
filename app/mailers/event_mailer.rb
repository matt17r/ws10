class EventMailer < ApplicationMailer
  helper BadgesHelper

  default from: email_address_with_name("matt@ws10.run", "Western Sydney 10")

  def result_notification(result:)
    @event = result.event
    @result = result
    @user = result.user
    @result_count = @user.results.count
    @location_count = @user.results.joins(:event).where(events: { location: @event.location }).count

    @newly_earned_badges = @user.user_badges
      .for_event(@event)
      .includes(:badge)
      .joins(:badge)
      .order("badges.badge_family")

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

    @newly_earned_badges = @user.user_badges
      .for_event(@event)
      .includes(:badge)
      .joins(:badge)
      .order("badges.badge_family")

    mail(
      to: email_address_with_name(@user.email_address, @user.name),
      subject: "You participated in WS10 ##{@event.number} at #{@event.location}"
    )
  end

  def volunteer_notification(volunteer:)
    @event = volunteer.event
    @volunteer = volunteer
    @user = volunteer.user
    @volunteer_count = @user.volunteers.count
    @location_count = @user.volunteers.joins(:event).where(events: { location: @event.location }).count
    @total_runs = @user.results.where.not(time: nil).count
    @total_events = @user.results.count + @volunteer_count
    @is_first_timer = @total_events == 1

    @newly_earned_badges = @user.user_badges
      .for_event(@event)
      .includes(:badge)
      .joins(:badge)
      .order("badges.badge_family")

    mail(
      to: email_address_with_name(@user.email_address, @user.name),
      subject: "Thank you for volunteering at WS10 ##{@event.number} at #{@event.location}"
    )
  end
end
