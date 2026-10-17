class CheckInsController < ApplicationController
  include AdminAuthentication

  skip_before_action :require_admin!, only: [ :show, :create, :create_for_friend, :update_time, :destroy ]
  allow_unauthenticated_access only: [ :show, :create ]

  before_action :set_check_in_event, only: [ :show, :create, :create_for_friend, :update_time ]

  def show
    if @event
      @check_in = @event.check_ins.find_by(user: Current.user) if authenticated?
    else
      @next_event = Event.next_for_check_in
    end
  end

  def create
    unless @event
      redirect_to check_in_path, alert: "Check-in isn't open right now."
      return
    end

    unless authenticated?
      session[:return_to_after_authenticating] = check_in_path
      redirect_to sign_in_path, notice: "Please sign in to check in to this event."
      return
    end

    check_in = CheckIn.check_in!(event: @event, user: Current.user, status: check_in_status)
    redirect_to check_in_path, notice: check_in.pending? ? "Late check-in submitted. An organiser will approve it soon." : "You're checked in!"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to check_in_path, alert: "Could not check in: #{e.record.errors.full_messages.to_sentence}"
  end

  def create_for_friend
    unless @event
      redirect_to check_in_path, alert: "Check-in isn't open right now."
      return
    end

    unless @event.check_ins.exists?(user: Current.user)
      redirect_to check_in_path, alert: "Please check yourself in first."
      return
    end

    friend = User.find_by_barcode(params[:barcode])

    unless friend
      redirect_to check_in_path, alert: "No user found with barcode #{params[:barcode]}. Please check the barcode and try again."
      return
    end

    check_in = CheckIn.check_in!(event: @event, user: friend, status: check_in_status)
    flash[:check_in_message] = check_in.pending? ? "Late check-in submitted for #{friend.display_name}." : "#{friend.display_name} has been checked in!"
    redirect_to check_in_path, notice: "Success!"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to check_in_path, alert: "Could not check in #{friend.display_name}: #{e.record.errors.full_messages.to_sentence}"
  end

  def update_time
    check_in = @event&.check_ins&.find_by(user: Current.user)

    unless check_in
      redirect_to check_in_path, alert: "Please check in first."
      return
    end

    check_in.record_time!(params[:time_string])
    redirect_to check_in_path, notice: check_in.recorded_time_string ? "Time saved: #{check_in.recorded_time_string}." : "Time removed."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to check_in_path, alert: "Could not save your time: #{e.record.errors.full_messages.to_sentence}"
  end

  def destroy
    check_in = CheckIn.find(params[:id])

    if admin_signed_in?
      check_in.withdraw!
      redirect_to event_path(check_in.event.number), notice: "Check-in removed for #{check_in.user.name}."
    elsif check_in.user != Current.user
      redirect_to user_path, alert: "You can only cancel your own check-in."
    elsif check_in.pending? || check_in.event.open_for_check_in?
      check_in.withdraw!
      redirect_to check_in_path, notice: "Check-in cancelled."
    else
      redirect_to user_path, alert: "Check-in can no longer be cancelled."
    end
  rescue ActiveRecord::RecordNotFound
    if admin_signed_in?
      redirect_to dashboard_path, alert: "Check-in not found."
    else
      redirect_to user_path, alert: "Check-in not found."
    end
  end

  def approve
    check_in = CheckIn.find(params[:id])
    check_in.approve!
    redirect_to event_path(check_in.event.number), notice: "Late check-in approved for #{check_in.user.name}."
  end

  private

  def set_check_in_event
    @event = Event.open_for_check_in
    @late = @event.nil?
    @event ||= Event.accepting_late_check_ins
  end

  def check_in_status
    @late ? "pending" : "approved"
  end
end
