class Admin::UsersCleanupController < ApplicationController
  include AdminAuthentication

  def index
    @never_confirmed_users = User.never_confirmed.order(created_at: :desc)
    @confirmed_but_inactive_users = User.confirmed_but_inactive.order(confirmed_at: :desc)
  end

  def send_reminders
    user_ids = params[:user_ids]&.reject(&:blank?) || []

    if user_ids.empty?
      redirect_to admin_users_cleanup_url, alert: "No users selected."
      return
    end

    users = User.where(id: user_ids)
    users.each do |user|
      UsersMailer.inactive_reminder(user).deliver_later
    end

    redirect_to admin_users_cleanup_url, notice: "Sent reminder emails to #{users.count} users."
  end

  def bulk_delete
    user_ids = params[:user_ids]&.reject(&:blank?) || []

    if user_ids.empty?
      redirect_to admin_users_cleanup_url, alert: "No users selected."
      return
    end

    users = User.where(id: user_ids)
    count = users.count
    users.destroy_all

    redirect_to admin_users_cleanup_url, notice: "Deleted #{count} users."
  end
end
