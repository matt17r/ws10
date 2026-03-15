class Webhooks::KitController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :verify_authenticity_token

  INACTIVE_EVENTS = %w[subscriber.subscriber_unsubscribe subscriber.subscriber_bounce subscriber.subscriber_complain].freeze

  def create
    return head :unauthorized unless valid_token?

    email = params.dig(:subscriber, :email_address)
    return head :unprocessable_entity unless email

    user = User.find_by(email_address: email)
    if user
      if INACTIVE_EVENTS.include?(params[:type])
        user.update!(newsletter_subscribed: false, newsletter_opt_in: false)
      elsif params[:type] == "subscriber.subscriber_activate"
        user.update!(newsletter_subscribed: true, newsletter_opt_in: true)
      end
    end

    head :ok
  end

  private

  def valid_token?
    webhook_secret = Rails.application.credentials.dig(:kit, :webhook_secret)
    webhook_secret.present? && ActiveSupport::SecurityUtils.secure_compare(params[:token].to_s, webhook_secret)
  end
end
