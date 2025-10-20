class ResultsController < ApplicationController
  include AdminAuthentication

  before_action :set_result, only: [ :edit, :update, :destroy ]

  def new
    @event = Event.find(params[:event_id])
    @result = @event.results.build
  end

  def edit
  end

  def create
    @event = Event.find(params[:result][:event_id])
    @result = @event.results.build(result_params)

    if @result.save
      user_name = @result.user_name
      redirect_to edit_results_admin_event_path(@result.event.number), notice: "Result created for #{user_name}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @result.update(result_params)
      user_name = @result.user_name
      redirect_to edit_results_admin_event_path(@result.event.number), notice: "Result updated for #{user_name}."
    else
      render :edit
    end
  end

  def link
    event = Event.find(params[:event_id])
    all_positions = (event.finish_positions.pluck(:position) + event.finish_times.pluck(:position)).uniq.sort
    created = []
    skipped = []
    all_positions.each do |position|
      fp = event.finish_positions.find_by(position: position)
      ft = event.finish_times.find_by(position: position)
      next unless fp || ft
      next if fp&.discarded?

      user = fp&.user
      time = ft&.time

      already_linked = user.present? && event.results.exists?(user: user, time: time)

      unless already_linked
        result = event.results.build(user: user, time: time)
        if result.save
          created << position
        else
          skipped << "#{position} (#{result.errors.full_messages.to_sentence})"
        end
      else
        skipped << "#{position} (already linked)"
      end
    end

    if skipped.empty?
      redirect_to dashboard_path, notice: "Linked #{created.count} results successfully."
    else
      redirect_to dashboard_path, alert: "Linked #{created.count} results. Skipped: #{skipped.join(', ')}"
    end
  end

  def destroy
    event = @result.event
    user_name = @result.user_name
    if @result.destroy
      redirect_to edit_results_admin_event_path(event.number), notice: "Result deleted for #{user_name}"
    else
      redirect_to edit_results_admin_event_path(event.number), alert: @result.errors.full_messages.to_sentence
    end
  end

  def destroy_all
    event = Event.find(params[:event_id])
    count = event.results.count

    event.results.destroy_all

    redirect_to dashboard_path, notice: "Deleted #{count} results"
  end

  private

  def set_result
    @result = Result.find(params[:id])
  end

  def result_params
    params.require(:result).permit(:user_id, :time_string)
  end
end
