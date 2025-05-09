class EventsController < ApplicationController
  allow_unauthenticated_access(only: [ :index, :show, :show_latest ])

  def index
    @events = Event.all.order(number: :desc).includes(:results)
  end

  def show
    set_event
    return redirect_to results_path unless @event.present?
    @results = @event.results.order(Result.arel_table[:time].asc.nulls_last).includes(:user)
    @volunteers = @event.volunteers.order(:role).includes(:user)
  end

  def show_latest
    @event = Event.order(number: :desc).first
    @results = @event.results.order(Result.arel_table[:time].asc.nulls_last).includes(:user)
    @volunteers = @event.volunteers.order(:role).includes(:user)
    render :show
  end

  private

  def set_event
    @event = Event.find_by number: params[:number]
  end
end
