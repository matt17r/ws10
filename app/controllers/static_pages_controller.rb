class StaticPagesController < ApplicationController
  allow_unauthenticated_access(only: [ :about, :home, :results ])

  def about
  end

  def admin_dashboard
    @event = Event.in_progress.order(date: :asc).includes(:finish_positions, :finish_times, :results, :volunteers, :location).first
  end

  def home
    @upcoming_events = Event.in_progress.includes(:location).where("date >= ?", Date.today).order(:date).limit(3)
    @statistics = Event.home_statistics
  end

  def results
  end

  def invalidate_statistics_cache
    Event.invalidate_home_statistics_cache
    redirect_to dashboard_path, notice: "Statistics cache has been invalidated."
  end
end
