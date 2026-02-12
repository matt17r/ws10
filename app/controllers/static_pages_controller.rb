class StaticPagesController < ApplicationController
  allow_unauthenticated_access(only: [ :about, :home, :results ])

  def about
  end

  def support
  end

  def admin_dashboard
    @event = Event.not_finalised.order(date: :asc).includes(:finish_positions, :finish_times, :results, :volunteers, :location).first
  end

  def home
    @upcoming_events = Event.upcoming_for_home.includes(:location).where("date >= ?", Date.today).order(:date).limit(3)
    @statistics = Event.home_statistics

    if authenticated? && (active_event = @upcoming_events.find(&:active?))
      @current_user_checked_in = active_event.check_ins.exists?(user: Current.session.user)
      @active_event_token = CheckIn.token_for_event(active_event.number)
    end
  end

  def results
  end

  def invalidate_statistics_cache
    Event.invalidate_home_statistics_cache
    redirect_to dashboard_path, notice: "Statistics cache has been invalidated."
  end
end
