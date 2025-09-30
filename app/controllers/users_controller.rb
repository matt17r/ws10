class UsersController < ApplicationController
  before_action :set_current_user, only: [ :show, :edit, :update ]

  def show
  end

  def edit
  end

  def import
    if params[:file].present?
      created = 0
      skipped = 0
      errors = 0
      CSV.foreach(params[:file], headers: true) do |row|
        unless row["email_address"].present? && row["name"].present?
          puts "Could not import user - #{row}"
          error += 1
          next
        end

        user = User.create({
            email_address: row["email_address"],
            name: row["name"],
            display_name: row["display_name"],
            password: SecureRandom.hex(12)
          })

        if user.persisted?
          created += 1
        else
          skipped += 1
        end
      end
      redirect_to admin_users_path, notice: "#{created} users created (#{skipped} skipped, #{errors} errors)."
    else
      redirect_to admin_users_path, alert: "No file selected/uploaded."
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
