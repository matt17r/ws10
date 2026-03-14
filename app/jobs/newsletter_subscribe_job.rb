class NewsletterSubscribeJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    subscriber = KitClient.new.subscribe(email: user.email_address, name: user.name)
    user.update!(newsletter_subscribed: true) if subscriber
  end
end
