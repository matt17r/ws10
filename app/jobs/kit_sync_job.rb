class KitSyncJob < ApplicationJob
  queue_as :default

  def perform
    client = KitClient.new
    subscribers = client.list_subscribers
    non_user_tag_id = Rails.application.credentials.dig(:kit, :non_user_tag_id)

    confirmed_emails = User.where.not(confirmed_at: nil).pluck(:email_address).to_set

    subscribers.each do |subscriber|
      email = subscriber["email_address"]
      user = User.find_by(email_address: email)

      if user
        user.update!(newsletter_subscribed: true) unless user.newsletter_subscribed?
      elsif non_user_tag_id
        client.add_tag(subscriber_id: subscriber["id"], tag_id: non_user_tag_id)
      end
    end

    subscribed_emails = subscribers.map { |s| s["email_address"] }.to_set
    User.where(newsletter_subscribed: true).find_each do |user|
      user.update!(newsletter_subscribed: false) unless subscribed_emails.include?(user.email_address)
    end
  end
end
