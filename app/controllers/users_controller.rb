class UsersController < ApplicationController
  before_action :set_current_user, only: [ :show, :edit, :update ]

  def show
  end

  def edit
  end

  def import
    if params[:file].present?
      redirect_to users_path, notice: 'Users imported successfully.'
    else
      redirect_to users_path, alert: 'No file uploaded.'
    end
  end

  def download_template
    send_data User.csv_template, filename: "user_template.csv", type: "text/csv; charset=utf-8"
  end

  def update
    @user.assign_attributes(user_params)
    @show_password_fields = params[:change_password].present?

    if @show_password_fields
      unless User.authenticate_by(email_address: user_params[:email_address], password: user_params[:current_password])
        @user.errors.add(:current_password, "is incorrect")
        flash.now[:alert] = "Your current password is incorrect."
        return render :edit, status: :unprocessable_entity
      end
    end

    if @user.save
      redirect_to user_path, notice: "Profile updated"
    else
      flash.now[:alert] = "An error prevented your profile from being saved"
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_current_user
    @user = Current.user
  end

  def user_params
    params.require(:user).permit(:name, :email_address, :display_name, :emoji, :current_password, :password, :password_confirmation)
  end
end
