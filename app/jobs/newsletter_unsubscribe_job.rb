class NewsletterUnsubscribeJob < ApplicationJob
  queue_as :default
  retry_on KitClient::RateLimitError, wait: 30.seconds, attempts: 5

  def perform(user_id)
    user = User.find(user_id)
    client = KitClient.new
    subscriber = client.find_subscriber(email: user.email_address)

    if subscriber
      client.unsubscribe(subscriber_id: subscriber["id"])
    end

    user.update!(newsletter_subscribed: false)
  end
end
