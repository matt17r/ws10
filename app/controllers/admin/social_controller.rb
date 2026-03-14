class Admin::SocialController < ApplicationController
  include AdminAuthentication

  STRAVA_CLUB_URL = "https://www.strava.com/clubs/ws10"
  SITE_BASE_URL = "https://ws10.run"
  SCHEDULE_DELAY_MINUTES = 15

  def show
    @default_scheduled_at = SCHEDULE_DELAY_MINUTES.minutes.from_now
    @upcoming_event = Event
      .joins(:location)
      .where("date >= ?", Date.today)
      .where.not(status: [ :finalised, :abandoned, :cancelled ])
      .order(:date)
      .includes(:location)
      .first

    @recent_event = Event
      .where(status: :finalised)
      .order(date: :desc)
      .includes(:location, volunteers: :user)
      .first

    @pre_event_message = pre_event_message(@upcoming_event) if @upcoming_event
    @post_event_message = post_event_message(@recent_event) if @recent_event
    @message = case params[:template]
    when "pre_event" then @pre_event_message
    when "post_event" then @post_event_message
    end
    @facebook_configured = facebook_configured?
    @strava_club_url = STRAVA_CLUB_URL
  end


  def post_facebook
    message = params[:message].to_s.strip

    if message.blank?
      redirect_to admin_social_path, alert: "Message cannot be blank."
      return
    end

    unless facebook_configured?
      redirect_to admin_social_path, alert: "Facebook is not configured. Add facebook.page_id and facebook.page_token to credentials."
      return
    end

    scheduled_at = Time.zone.parse(params[:scheduled_at].to_s)
    scheduled_at = SCHEDULE_DELAY_MINUTES.minutes.from_now if scheduled_at.nil? || scheduled_at < SCHEDULE_DELAY_MINUTES.minutes.from_now

    result = post_to_facebook(message, scheduled_at)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("facebook_result",
          partial: "admin/social/facebook_result",
          locals: { result: result }),
          status: result[:success] ? :ok : :unprocessable_entity
      end
      format.html do
        if result[:success]
          redirect_to admin_social_path, notice: "Post scheduled successfully (ID: #{result[:id]})."
        else
          redirect_to admin_social_path, alert: "Facebook post failed: #{result[:error]}"
        end
      end
    end
  end

  private

  def pre_event_message(event)
    location = event.location
    date_str = event.date.strftime("%A, %-d %B")
    course_url = "#{SITE_BASE_URL}/courses/#{location.slug}"

    lines = [
      "WS10 #{event.number} is this #{date_str} at #{location.name}. We'd love to see you there!",
      "",
      "For more details, visit the course page on the website: #{course_url}"
    ]

    lines << "Facebook event: #{event.facebook_url}" if event.facebook_url.present?
    lines << "Strava event: #{event.strava_url}" if event.strava_url.present?

    lines.join("\n")
  end

  def post_event_message(event)
    results_url = "#{SITE_BASE_URL}/events/#{event.number}"

    lines = []
    lines << event.description if event.description.present?
    lines << "" if lines.any?

    volunteer_names = event.volunteers.includes(:user).map { |v| v.user.name }
    lines << "Thank you to #{volunteer_names.to_sentence} for volunteering!" if volunteer_names.any?
    lines << "" if volunteer_names.any?

    lines << "Full results on the website: #{results_url}"

    lines.join("\n")
  end

  def facebook_configured?
    Rails.application.credentials.facebook&.page_id.present? &&
      Rails.application.credentials.facebook&.page_token.present?
  end

  def post_to_facebook(message, scheduled_at)
    require "net/http"
    require "json"

    page_id = Rails.application.credentials.facebook.page_id
    token = Rails.application.credentials.facebook.page_token
    scheduled_time = scheduled_at.to_i

    uri = URI("https://graph.facebook.com/v21.0/#{page_id}/feed")
    response = Net::HTTP.post_form(uri, {
      "message" => message,
      "access_token" => token,
      "published" => "false",
      "scheduled_publish_time" => scheduled_time
    })
    body = JSON.parse(response.body)

    if response.is_a?(Net::HTTPSuccess) && body["id"]
      Rails.logger.info "Facebook post scheduled: #{body["id"]}"
      { success: true, id: body["id"] }
    else
      Rails.logger.error "Facebook post failed: #{body}"
      { success: false, error: body.dig("error", "message") || "Unknown error" }
    end
  rescue => e
    { success: false, error: e.message }
  end
end
