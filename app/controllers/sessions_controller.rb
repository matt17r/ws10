class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later" }

  def new
    redirect_back(fallback_location: root_path, notice: "You're already signed in") if Current.session
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      if user.confirmed?
        start_new_session_for user
        redirect_to after_authentication_url, notice: "Signed in"
      else
        user.send_confirmation_email
        redirect_to root_path, notice: "Please click the link in the verification email we just sent you to confirm your account"
      end
    else
      flash.now[:alert] = "Email address or password is invalid. Please try again"
      render :new
    end
  end

  def destroy
    terminate_session
    redirect_to root_path
  end
end
