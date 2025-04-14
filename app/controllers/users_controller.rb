class UsersController < ApplicationController
  before_action :set_current_user, only: [ :show, :edit, :update ]

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to profile_path, notice: "Profile updated"
    else
      render :edit
    end
  end

  private

  def set_current_user
    @user = Current.user
  end

  def user_params
    params.require(:user).permit(:name, :email, :avatar) # etc.
  end
end
