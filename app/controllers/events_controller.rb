class EventsController < ApplicationController
  include AdminAuthentication

  skip_before_action :require_admin!, only: [ :index, :show, :show_latest ]
  allow_unauthenticated_access(only: [ :index, :show, :show_latest ])

  before_action :set_event, only: [ :show, :edit, :update, :destroy, :edit_results ]

  # Public actions
  def index
    @events = Event.where(results_ready: true).order(number: :desc).includes(:results)
  end

  def show
    return redirect_to results_path unless @event.present?
    @results = @event.results.order(Result.arel_table[:time].asc.nulls_last).includes(:user)
    @volunteers = @event.volunteers.order(:role).includes(:user)
  end

  def show_latest
    @event = Event.where(results_ready: true).order(number: :desc).first
    @results = @event.results.order(Result.arel_table[:time].asc.nulls_last).includes(:user)
    @volunteers = @event.volunteers.order(:role).includes(:user)
    render :show
  end

  # Admin actions
  def new
    @event = Event.new(number: (Event.maximum(:number) || 0) + 1, date: Date.today)
  end

  def create
    @event = Event.new(event_params)
    if @event.save
      redirect_to event_path(@event), notice: "Event #{@event} created."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to event_path(@event), notice: "Event #{@event} updated."
    else
      render :edit
    end
  end

  def destroy
    @event.destroy
    redirect_to events_path, alert: "Event #{@event} deleted."
  end

  def edit_results
    @results = @event.results.order(Result.arel_table[:time].asc.nulls_last).includes(:user)
    @volunteers = @event.volunteers.order(:role).includes(:user)
  end

  private

  def set_event
    @event = Event.find_by number: params[:number]
  end

  def event_params
    params.expect(event: [ :number, :date, :location, :description, :results_ready ])
  end
end
