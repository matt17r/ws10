class CoursesController < ApplicationController
  allow_unauthenticated_access

  def index
    next_event = Event.where("date >= ?", Date.today).where(results_ready: false).order(:date).first

    if next_event&.location
      redirect_to course_path(next_event.location.slug)
    else
      recent_event = Event.order(date: :desc).first
      if recent_event&.location
        redirect_to course_path(recent_event.location.slug)
      else
        redirect_to root_path
      end
    end
  end

  def show
    @location = Location.find_by!(slug: params[:slug])
    @locations = Location.all.order(:name)
    @next_event = Event.where("date >= ?", Date.today).order(:date).first
    @latest_event = @location.latest_event
    @current_year_events = @location.events.where("strftime('%Y', date) = ?", Date.today.year.to_s).order(:date)
  end
end
