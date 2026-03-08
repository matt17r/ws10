class Admin::SocialController < ApplicationController
  include AdminAuthentication

  STRAVA_CLUB_URL = "https://www.strava.com/clubs/ws10"
  SITE_BASE_URL = "https://ws10.run"

  def show
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
      redirect_to admin_social_path, alert: "Facebook is not configured. Add facebook.access_token to credentials."
      return
    end

    result = post_to_facebook(message)

    if result[:success]
      redirect_to admin_social_path, notice: "Posted to Facebook successfully!"
    else
      redirect_to admin_social_path, alert: "Facebook post failed: #{result[:error]}"
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
      "For more details, visit the course page on our website: #{course_url}"
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

    lines << "Full results at #{results_url}"

    lines.join("\n")
  end

  def facebook_configured?
    Rails.application.credentials.facebook&.access_token.present?
  end

  def fetch_facebook_page
    require "net/http"
    require "json"

    token = Rails.application.credentials.facebook&.access_token
    uri = URI("https://graph.facebook.com/v21.0/me/accounts")
    uri.query = URI.encode_www_form(access_token: token, fields: "id,name,access_token")

    response = Net::HTTP.get_response(uri)
    body = JSON.parse(response.body)

    return nil unless response.is_a?(Net::HTTPSuccess) && body["data"]&.any?

    page = body["data"].first
    { id: page["id"], token: page["access_token"] }
  rescue => e
    nil
  end

  def post_to_facebook(message)
    require "net/http"
    require "json"

    page = fetch_facebook_page
    return { success: false, error: "Could not retrieve Facebook page details." } unless page

    uri = URI("https://graph.facebook.com/v21.0/#{page[:id]}/feed")
    response = Net::HTTP.post_form(uri, { "message" => message, "access_token" => page[:token] })
    body = JSON.parse(response.body)

    if response.is_a?(Net::HTTPSuccess) && body["id"]
      { success: true, id: body["id"] }
    else
      { success: false, error: body.dig("error", "message") || "Unknown error" }
    end
  rescue => e
    { success: false, error: e.message }
  end
end
