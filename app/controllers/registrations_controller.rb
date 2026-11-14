class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  before_action :validate_cloudflare_turnstile, only: [ :create ] if Rails.env.production?
  rescue_from RailsCloudflareTurnstile::Forbidden, with: :forbidden_turnstile

  def new
    @user = User.new(display_name: nil)
  end

  def create
    @user = User.new(user_params)
    if @user.valid? && @user.save
      @user.send_confirmation_email
      redirect_to root_path, notice: "Almost there! Please check your email to confirm your account"
    else
      flash.now[:alert] = "Could not create account. Please check the errors indicated below"
      render :new
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :display_name, :email_address, :password, :password_confirmation)
  end

  def forbidden_turnstile
    flash[:alert] = "Turnstile (bot protection) error, please reload the page and try again."
    redirect_to root_path
  end
end
