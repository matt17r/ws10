class StaticPagesController < ApplicationController
  allow_unauthenticated_access(only: [ :about, :home, :results ])

  def about
  end

  def admin_dashboard
    @event = Event.in_progress.order(date: :asc).includes(:finish_positions, :finish_times, :results, :volunteers, :location).first
  end

  def home
    @upcoming_events = Event.in_progress.includes(:location).where("date >= ?", Date.today).order(:date).limit(3)
  end

  def results
  end
end
