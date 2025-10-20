class VolunteersController < ApplicationController
  include AdminAuthentication

  before_action :set_volunteer, only: [ :edit, :update, :destroy ]

  def new
    @event = Event.find(params[:event_id])
    @volunteer = @event.volunteers.build
  end

  def edit
  end

  def create
    @event = Event.find(params[:volunteer][:event_id])
    @volunteer = @event.volunteers.build(volunteer_params)

    if @volunteer.save
      redirect_to edit_results_admin_event_path(@volunteer.event.number), notice: "Volunteer created for #{@volunteer.user.name}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @volunteer.update(volunteer_params)
      redirect_to edit_results_admin_event_path(@volunteer.event.number), notice: "Volunteer updated for #{@volunteer.user.name}."
    else
      render :edit
    end
  end

  def destroy
    event = @volunteer.event
    user_name = @volunteer.user.name
    if @volunteer.destroy
      redirect_to edit_results_admin_event_path(event.number), notice: "Volunteer deleted for #{user_name}"
    else
      redirect_to edit_results_admin_event_path(event.number), alert: @volunteer.errors.full_messages.to_sentence
    end
  end

  private

  def set_volunteer
    @volunteer = Volunteer.find(params[:id])
  end

  def volunteer_params
    params.require(:volunteer).permit(:user_id, :role)
  end
end
