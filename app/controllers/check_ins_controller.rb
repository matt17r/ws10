class CheckInsController < ApplicationController
  include AdminAuthentication

  skip_before_action :require_admin!, only: [:show, :create, :destroy]
  allow_unauthenticated_access only: [:show, :create]

  def show
    @event = find_active_event
    parse_token! if @event

    unless @event
      redirect_to root_path, alert: "No active event for check-in."
      return
    end

    @already_checked_in = current_user_checked_in? if authenticated?
  end

  def create
    @event = find_active_event
    parse_token! if @event

    unless @event
      redirect_to root_path, alert: "No active event for check-in."
      return
    end

    unless authenticated?
      session[:return_to_after_authenticating] = check_in_path(params[:token])
      redirect_to sign_in_path, notice: "Please sign in to check in to this event."
      return
    end

    perform_check_in!(Current.session.user)
    redirect_to user_path
  rescue ActiveRecord::RecordInvalid => e
    redirect_to user_path, alert: "Could not check in: #{e.message}"
  end

  def destroy
    check_in = CheckIn.find(params[:id])

    unless admin_signed_in? || check_in.user == Current.session.user
      redirect_to user_path, alert: "You can only cancel your own check-in."
      return
    end

    event = check_in.event

    check_in.destroy!

    if admin_signed_in?
      redirect_to event_path(event.number), notice: "Check-in removed for #{check_in.user.name}."
    else
      redirect_to courses_path, notice: "Check-in cancelled."
    end
  rescue ActiveRecord::RecordNotFound
    if admin_signed_in?
      redirect_to dashboard_path, alert: "Check-in not found."
    else
      redirect_to user_path, alert: "Check-in not found."
    end
  end

  private

  def find_active_event
    Event.where(status: "in_progress").first
  end

  def parse_token!
    token = params[:token]

    unless CheckIn.valid_token?(token, @event.number)
      raise ActiveRecord::RecordNotFound, "Invalid check-in token"
    end
  end

  def current_user_checked_in?
    @event.check_ins.exists?(user: Current.session.user)
  end

  def perform_check_in!(user)
    CheckIn.transaction do
      if @event.check_ins.exists?(user: user)
        raise ActiveRecord::RecordInvalid.new(CheckIn.new), "You have already checked in to this event"
      end

      @event.check_ins.create!(user: user, checked_in_at: Time.current)
    end
  end
end
