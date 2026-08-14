require "test_helper"

class NewsletterSubscribeJobTest < ActiveJob::TestCase
  test "marks the user subscribed when Kit returns an active subscriber" do
    user = users(:one)
    user.update!(newsletter_subscribed: false)

    with_kit_subscribe_returning("state" => "active") do
      NewsletterSubscribeJob.perform_now(user.id)
    end

    assert user.reload.newsletter_subscribed
  end

  test "does not mark the user subscribed while confirmation is pending" do
    user = users(:one)
    user.update!(newsletter_subscribed: false)

    with_kit_subscribe_returning("state" => "inactive") do
      NewsletterSubscribeJob.perform_now(user.id)
    end

    assert_not user.reload.newsletter_subscribed
  end

  test "does nothing when Kit returns no subscriber" do
    user = users(:one)
    user.update!(newsletter_subscribed: false)

    with_kit_subscribe_returning(nil) do
      NewsletterSubscribeJob.perform_now(user.id)
    end

    assert_not user.reload.newsletter_subscribed
  end

  private

  def with_kit_subscribe_returning(result)
    KitClient.alias_method :original_subscribe, :subscribe
    KitClient.define_method(:subscribe) { |email:, name:| result }
    yield
  ensure
    KitClient.alias_method :subscribe, :original_subscribe
    KitClient.remove_method :original_subscribe
  end
end
