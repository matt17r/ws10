class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :redirect_authenticated_users, only: %i[new create]
  before_action :sign_out_authenticated_user, only: %i[edit update]
  before_action :set_user_by_token, only: %i[ edit update ]

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to sign_in_path, notice: "Password reset instructions sent (if email address found)"
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.confirm!
      redirect_to sign_in_path, notice: "Password has been reset"
    else
      redirect_to edit_password_path(params[:token]), alert: "Passwords did not match"
    end
  end

  private

  def redirect_authenticated_users
    return unless Current.session
    redirect_back(fallback_location: root_path, notice: "You're already signed in")
  end

  def set_user_by_token
    @user = User.find_by_password_reset_token!(params[:token])
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to forgot_password_path, alert: "Password reset link is invalid or has expired"
  end

  def sign_out_authenticated_user
    return unless Current.session

    terminate_session
    flash.now[:alert] = "You have been signed out"
  end
end
