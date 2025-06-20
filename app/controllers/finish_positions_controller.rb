class FinishPositionsController < ApplicationController
  def create
    @finish_position = FinishPosition.new(finish_position_params)

    if @finish_position.save
      redirect_to dashboard_path, notice: "#{@finish_position.user&.name || "Unknown"} placed at ##{@finish_position.position}"
    else
      redirect_to dashboard_path, alert: "Can't add #{@finish_position.user&.name || "Unknown"} at ##{@finish_position.position}... #{@finish_position.errors.full_messages.to_sentence}"
    end
  end

  def destroy
    @finish_position = FinishPosition.find(params[:id])

    if @finish_position.destroy
      redirect_to dashboard_path, notice: "#{@finish_position.user&.name || "Unknown"} removed from ##{@finish_position.position}"
    else
      redirect_to dashboard_path, alert: @finish_position.errors.full_messages.to_sentence
    end
  end

  private

  def finish_position_params
    params.require(:finish_position).permit(:user_id, :event_id, :position)
  end
end
