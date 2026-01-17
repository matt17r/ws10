class FinishPositionsController < ApplicationController
  allow_unauthenticated_access only: [ :show_claim, :claim ]

  def show_claim
    parse_token!

    unless @event
      redirect_to root_path, alert: "No active event. Please let the organisers know."
      return
    end

    @claimed_position = @event.finish_positions.find_by(position: @position) if position_claimed?

    if authenticated?
      @user_claimed_position = @event.finish_positions.find_by(user: Current.session.user)
      @user_has_claimed = @user_claimed_position.present?
    end
  end

  def claim
    parse_token!

    unless @event
      redirect_to root_path, alert: "No active event. Please contact the organizers."
      return
    end

    unless authenticated?
      session[:return_to_after_authenticating] = claim_finish_token_path(params[:token_prefix], params[:position])
      redirect_to sign_in_path, notice: "Please sign in to claim your finish position."
      return
    end

    claim_position!(Current.session.user)
    redirect_to user_path, notice: "Successfully claimed position ##{@position}!"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to user_path, alert: "Could not claim position: #{e.message}"
  rescue ActiveRecord::RecordNotFound => e
    redirect_to root_path, alert: e.message
  end

  def claim_for_friend
    parse_token!

    unless @event
      redirect_to root_path, alert: "No active event. Please contact the organizers."
      return
    end

    friend = User.find_by_barcode(params[:barcode])

    unless friend
      redirect_to claim_finish_token_path(params[:token_prefix], params[:position]),
                  alert: "No user found with barcode #{params[:barcode]}. Please check the barcode and try again."
      return
    end

    existing_position = @event.finish_positions.find_by(user: friend)
    if existing_position
      redirect_to claim_finish_token_path(params[:token_prefix], params[:position]),
                  alert: "#{friend.display_name} has already claimed position ##{existing_position.position}. Please see an organiser."
      return
    end

    claim_position!(friend)
    redirect_to user_results_path(friend.barcode_string), notice: "Successfully claimed position ##{@position} for #{friend.display_name}!"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to claim_finish_token_path(params[:token_prefix], params[:position]), alert: "Could not claim position: #{e.message}"
  rescue ActiveRecord::RecordNotFound => e
    redirect_to root_path, alert: e.message
  end

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

  def parse_token!
    prefix = params[:token_prefix]
    position = params[:position].to_i

    unless FinishPosition.valid_token?(prefix, position)
      raise ActiveRecord::RecordNotFound, "Invalid token"
    end

    @position = position
    @event = Event.where(status: "in_progress").first
  end

  def position_claimed?
    @event.finish_positions.exists?(position: @position)
  end

  def claim_position!(user)
    FinishPosition.transaction do
      if position_claimed?
        raise ActiveRecord::RecordInvalid.new(FinishPosition.new), "Position already claimed"
      end

      if @event.finish_positions.exists?(user: user)
        raise ActiveRecord::RecordInvalid.new(FinishPosition.new), "You have already claimed a position for this event"
      end

      @event.finish_positions.create!(user: user, position: @position)
    end
  end

  def finish_position_params
    params.require(:finish_position).permit(:user_id, :event_id, :position, :discarded)
  end

  def user_params
    params.require(:user).permit(:name, :email_address, :display_name)
  end
end
