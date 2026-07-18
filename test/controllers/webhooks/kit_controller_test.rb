require "test_helper"

class Webhooks::KitControllerTest < ActionDispatch::IntegrationTest
  SECRET = "test-webhook-secret"

  test "unsubscribe event clears newsletter flags for matching user" do
    user = users(:one)
    user.update!(newsletter_subscribed: true, newsletter_opt_in: true)

    with_webhook_secret do
      post kit_webhook_path(token: SECRET, type: "subscriber.subscriber_unsubscribe"),
        params: { subscriber: { email_address: user.email_address } }
    end

    assert_response :ok
    user.reload
    assert_not user.newsletter_subscribed
    assert_not user.newsletter_opt_in
  end

  test "bounce event clears newsletter flags for matching user" do
    user = users(:one)
    user.update!(newsletter_subscribed: true, newsletter_opt_in: true)

    with_webhook_secret do
      post kit_webhook_path(token: SECRET, type: "subscriber.subscriber_bounce"),
        params: { subscriber: { email_address: user.email_address } }
    end

    assert_response :ok
    assert_not user.reload.newsletter_subscribed
  end

  test "activate event sets newsletter flags for matching user" do
    user = users(:one)
    user.update!(newsletter_subscribed: false, newsletter_opt_in: false)

    with_webhook_secret do
      post kit_webhook_path(token: SECRET, type: "subscriber.subscriber_activate"),
        params: { subscriber: { email_address: user.email_address } }
    end

    assert_response :ok
    user.reload
    assert user.newsletter_subscribed
    assert user.newsletter_opt_in
  end

  test "unknown email returns ok without changing any user" do
    with_webhook_secret do
      post kit_webhook_path(token: SECRET, type: "subscriber.subscriber_unsubscribe"),
        params: { subscriber: { email_address: "nobody@example.com" } }
    end

    assert_response :ok
  end

  test "missing subscriber email returns unprocessable entity" do
    with_webhook_secret do
      post kit_webhook_path(token: SECRET, type: "subscriber.subscriber_unsubscribe")
    end

    assert_response :unprocessable_entity
  end

  test "invalid token returns unauthorized and changes nothing" do
    user = users(:one)
    user.update!(newsletter_subscribed: true, newsletter_opt_in: true)

    with_webhook_secret do
      post kit_webhook_path(token: "wrong-token", type: "subscriber.subscriber_unsubscribe"),
        params: { subscriber: { email_address: user.email_address } }
    end

    assert_response :unauthorized
    assert user.reload.newsletter_subscribed
  end

  test "unknown event type returns ok without changing the user" do
    user = users(:one)
    user.update!(newsletter_subscribed: true, newsletter_opt_in: true)

    with_webhook_secret do
      post kit_webhook_path(token: SECRET, type: "subscriber.tag_add"),
        params: { subscriber: { email_address: user.email_address } }
    end

    assert_response :ok
    assert user.reload.newsletter_subscribed
  end

  private

  def with_webhook_secret
    fake_credentials = { kit: { webhook_secret: SECRET } }
    Rails.application.define_singleton_method(:credentials) { fake_credentials }
    yield
  ensure
    Rails.application.singleton_class.remove_method(:credentials)
  end
end
