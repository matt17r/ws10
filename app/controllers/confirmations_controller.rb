class ConfirmationsController < ApplicationController
  allow_unauthenticated_access

  def create
    Current.user.send_confirmation_email
    redirect_to root_path, notice: "Confirmation email sent"
  end

  def show
    user = User.find_by_token_for(:user_confirmation, params[:token])
    if user.present? && user.confirm!
      start_new_session_for user
      redirect_to user_path, notice: "Thanks for confirming your address!"
    else
      redirect_to root_path, alert: "Invalid or expired confirmation link"
    end
  end
end
