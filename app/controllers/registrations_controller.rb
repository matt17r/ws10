class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
    @user = User.new
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
end
