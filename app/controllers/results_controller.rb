class ResultsController < ApplicationController
  def link
    event = Event.find(params[:event_id])
    fp = FinishPosition.find_by(event_id: params[:event_id], position: params[:position])
    ft = FinishTime.find_by(event_id: params[:event_id], position: params[:position])
    raise unless event && fp && ft
    @result = Result.create!(event: event, user: fp.user, time: ft.time)

    if @result.save
      redirect_to dashboard_path, notice: "Result created for #{params[:position]}"
    else
      redirect_to dashboard_path, alert: "Couldn't create result... #{@result.errors.full_messages.to_sentence}"
    end
  end

  def destroy
    @result = Result.find(params[:id])

    if @result.destroy
      redirect_to dashboard_path, notice: "Result deleted"
    else
      redirect_to dashboard_path, alert: @result.errors.full_messages.to_sentence
    end
  end
end
