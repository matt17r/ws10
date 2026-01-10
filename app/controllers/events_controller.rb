class EventsController < ApplicationController
  include AdminAuthentication

  skip_before_action :require_admin!, only: [ :index, :show, :show_latest ]
  allow_unauthenticated_access(only: [ :index, :show, :show_latest ])

  before_action :set_event, only: [ :show, :edit, :update, :destroy, :edit_results, :activate, :deactivate ]

  def index
    if Current.user&.admin?
      @events = Event.order(number: :desc).includes(:results)
    else
      @events = Event.where(status: "finalised").order(number: :desc).includes(:results)
    end
  end

  def show
    return redirect_to results_path unless @event.present?

    if @event.draft? && !Current.user&.admin?
      redirect_to results_path
      return
    end

    @results = @event.results.includes(user: { user_badges: :badge }).by_time
    @volunteers = @event.volunteers.includes(user: { user_badges: :badge }).by_role
  end

  def show_latest
    @event = Event.where(status: "finalised").order(number: :desc).first
    @results = @event.results.includes(user: { user_badges: :badge }).by_time
    @volunteers = @event.volunteers.includes(user: { user_badges: :badge }).by_role
    render :show
  end

  def new
    @event = Event.new(number: (Event.maximum(:number) || 0) + 1, date: Date.today)
  end

  def create
    @event = Event.new(event_params)
    if @event.save
      redirect_to dashboard_path, notice: "Event #{@event} created."
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
    @results = @event.results.by_time
    @volunteers = @event.volunteers.by_role
  end

  def activate
    @event.activate!
    redirect_to dashboard_path, notice: "Event #{@event} activated! Finish position claiming is now enabled."
  end

  def deactivate
    @event.deactivate!
    redirect_to dashboard_path, notice: "Event #{@event} deactivated! Finish position claiming is now disabled."
  end

  private

  def set_event
    @event = Event.find_by number: params[:number]
  end

  def event_params
    params.expect(event: [ :number, :date, :location_id, :description, :status, :facebook_url, :strava_url ])
  end
end
