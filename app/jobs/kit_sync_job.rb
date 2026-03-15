class KitSyncJob < ApplicationJob
  queue_as :default
  retry_on KitClient::RateLimitError, wait: 60.seconds, attempts: 3

  def perform
    client = KitClient.new
    subscribers = client.list_subscribers
    non_user_tag_id = Rails.application.credentials.dig(:kit, :non_user_tag_id)

    subscribers.each do |subscriber|
      email = subscriber["email_address"]
      user = User.find_by(email_address: email)

      if user
        user.update!(newsletter_opt_in: true, newsletter_subscribed: true) unless user.newsletter_subscribed?
      elsif non_user_tag_id
        client.add_tag(subscriber_id: subscriber["id"], tag_id: non_user_tag_id)
      end
    end

    subscribed_emails = subscribers.map { |s| s["email_address"] }.to_set
    User.where(newsletter_subscribed: true).find_each do |user|
      user.update!(newsletter_opt_in: false, newsletter_subscribed: false) unless subscribed_emails.include?(user.email_address)
    end
  end
end
