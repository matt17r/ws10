class NewsletterSubscribeJob < ApplicationJob
  queue_as :default
  retry_on KitClient::RateLimitError, wait: 30.seconds, attempts: 5

  def perform(user_id)
    user = User.find(user_id)
    subscriber = KitClient.new.subscribe(email: user.email_address, name: user.name)
    user.update!(newsletter_subscribed: true) if subscriber
  end
end
