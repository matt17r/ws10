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

    @close_to_achieving_badges = find_close_to_achieving_badges(@user)

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

    @close_to_achieving_badges = find_close_to_achieving_badges(@user)

    mail(
      to: email_address_with_name(@user.email_address, @user.name),
      subject: "You participated in WS10 ##{@event.number} at #{@event.location}"
    )
  end

  def volunteer_thank_you(volunteer:)
    @event = volunteer.event
    @volunteer = volunteer
    @user = volunteer.user
    @result_count = @user.results.count
    @volunteer_count = @user.volunteers.count

    @newly_earned_badges = @user.user_badges
      .for_event(@event)
      .includes(:badge)
      .joins(:badge)
      .order("badges.badge_family")

    @close_to_achieving_badges = find_close_to_achieving_badges(@user)

    mail(
      to: email_address_with_name(@user.email_address, @user.name),
      subject: "Thank you for volunteering at WS10 ##{@event.number}"
    )
  end

  private

  def find_close_to_achieving_badges(user)
    # Find badges where the user is close to achieving the next level
    # For example, if they have bronze, show progress toward silver
    close_badges = []

    user.user_badges.includes(badge: :family_badges).each do |user_badge|
      next_badge = user_badge.badge.next_level
      if next_badge && !user.badges.include?(next_badge)
        close_badges << next_badge
      end
    end

    close_badges.uniq
  end
end
