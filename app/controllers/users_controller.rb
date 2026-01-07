class UsersController < ApplicationController
  allow_unauthenticated_access only: [ :index, :results ]

  before_action :set_current_user, only: [ :show, :edit, :update, :my_results ]
  before_action :set_user, only: [ :results ]

  def index
    sort_column = params[:sort] || "display_name"
    sort_direction = params[:direction]

    @users = User.with_activity.sorted_by(sort_column, sort_direction)
    @sort_column = sort_column
    @sort_direction = sort_direction
  end

  def show
    @claimed_position = @user.finish_positions
      .joins(:event)
      .where(events: { status: "in_progress" })
      .first
  end

  def edit
  end

  def results
    @results = @user.results.includes(:event).order(created_at: :desc)
    @volunteers = @user.volunteers.includes(:event).order(created_at: :desc)
  end

  def my_results
    redirect_to user_results_path(barcode: @user.barcode_string)
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

  def set_user
    # Extract ID from barcode (e.g., "A000001" -> 1)
    if params[:barcode] =~ /\AA(\d+)\z/
      user_id = $1.to_i
      @user = User.find(user_id)
    else
      raise ActiveRecord::RecordNotFound
    end
  end
end
