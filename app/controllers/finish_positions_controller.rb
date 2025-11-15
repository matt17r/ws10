class FinishPositionsController < ApplicationController
  def create
    @finish_position = FinishPosition.new(finish_position_params)

    if params[:discard].present?
      @finish_position.discarded = true
    end

    if @finish_position.save
      status = @finish_position.discarded? ? "discarded" : "placed"
      name = @finish_position.user_name
      redirect_to dashboard_path, notice: "#{name} #{status} at ##{@finish_position.position}"
    else
      redirect_to dashboard_path, alert: "Can't add #{@finish_position.user_name} at ##{@finish_position.position}... #{@finish_position.errors.full_messages.to_sentence}"
    end
  end

  def destroy
    @finish_position = FinishPosition.find(params[:id])

    if @finish_position.destroy
      redirect_to dashboard_path, notice: "#{@finish_position.user_name} removed from ##{@finish_position.position}"
    else
      redirect_to dashboard_path, alert: @finish_position.errors.full_messages.to_sentence
    end
  end

  def new_user
    @finish_position = FinishPosition.find(params[:id])
    @user = User.new
  end

  def create_user
    @finish_position = FinishPosition.find(params[:id])

    @user = User.new(user_params)
    @user.password = SecureRandom.hex(12)
    @user.emoji = "👤"

    if @user.save
      @finish_position.update(user: @user)
      @user.send_confirmation_email
      redirect_to dashboard_path, notice: "#{@user.name} created and placed at ##{@finish_position.position}"
    else
      render :new_user, status: :unprocessable_entity
    end
  end

  private

  def finish_position_params
    params.require(:finish_position).permit(:user_id, :event_id, :position, :discarded)
  end

  def user_params
    params.require(:user).permit(:name, :email_address, :display_name)
  end
end
