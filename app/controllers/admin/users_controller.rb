class Admin::UsersController < ApplicationController
  include AdminAuthentication

  before_action :set_user, only: [ :show, :edit, :update, :confirm, :assign_role, :remove_role ]

  def index
    @users = User.includes(:roles)

    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      @users = @users.where(
        "LOWER(name) LIKE ? OR LOWER(email_address) LIKE ? OR LOWER(display_name) LIKE ?",
        search_term, search_term, search_term
      )
    end

    if params[:role].present? && params[:role] != "all"
      @users = @users.joins(:roles).where(roles: { name: params[:role] })
    end

    @users = @users.order(:name)
    @total_users = User.count
  end

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end


  def confirm
    @user.confirm!
    redirect_to admin_user_path(@user), notice: "#{@user.name}'s email has been confirmed."
  end

  def assign_role
    @role = Role.find(params[:role_id])

    unless @user.roles.include?(@role)
      @user.roles << @role
      redirect_to admin_user_path(@user), notice: "#{@role.name} role assigned to #{@user.name}."
    else
      redirect_to admin_user_path(@user), alert: "#{@user.name} already has the #{@role.name} role."
    end
  end

  def remove_role
    @role = Role.find(params[:role_id])

    if @user == Current.user && @role.name == "Administrator"
      redirect_to admin_user_path(@user), alert: "You cannot remove your own Administrator role."
      return
    end

    @user.roles.delete(@role)
    redirect_to admin_user_path(@user), notice: "#{@role.name} role removed from #{@user.name}."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email_address, :display_name, :emoji)
  end
end
