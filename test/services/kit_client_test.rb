require "test_helper"

class KitClientTest < ActiveSupport::TestCase
  test "subscribe creates the subscriber then adds them to the configured form" do
    client = KitClient.new
    requests = []
    client.define_singleton_method(:perform) do |uri, request|
      requests << { uri: uri.to_s, body: request.body && JSON.parse(request.body) }
      { "subscriber" => { "id" => 1, "email_address" => "a@example.com", "state" => "active" } }
    end

    with_form_id(7578400) do
      client.subscribe(email: "a@example.com", name: "Ada Lovelace")
    end

    assert_equal 2, requests.size
    assert_equal "#{KitClient::BASE_URL}/subscribers", requests[0][:uri]
    assert_equal({ "email_address" => "a@example.com", "first_name" => "Ada" }, requests[0][:body])
    assert_equal "#{KitClient::BASE_URL}/forms/7578400/subscribers", requests[1][:uri]
    assert_equal({ "email_address" => "a@example.com" }, requests[1][:body])
  end

  test "subscribe returns the subscriber from the add-to-form response" do
    client = KitClient.new
    client.define_singleton_method(:perform) do |uri, request|
      if uri.to_s.include?("/forms/")
        { "subscriber" => { "id" => 1, "email_address" => "a@example.com", "state" => "inactive" } }
      else
        { "subscriber" => { "id" => 1, "email_address" => "a@example.com", "state" => "cancelled" } }
      end
    end

    subscriber = with_form_id(7578400) { client.subscribe(email: "a@example.com", name: "Ada") }

    assert_equal "inactive", subscriber["state"]
  end

  test "delete_webhook issues an HTTP DELETE to /webhooks/:id" do
    client = KitClient.new
    captured = {}
    client.define_singleton_method(:perform) do |uri, request|
      captured[:uri] = uri
      captured[:request] = request
      {}
    end

    client.delete_webhook(webhook_id: 42)

    assert_instance_of Net::HTTP::Delete, captured[:request]
    assert_equal "#{KitClient::BASE_URL}/webhooks/42", captured[:uri].to_s
  end

  private

  def with_form_id(form_id)
    fake_kit = ActiveSupport::OrderedOptions.new
    fake_kit.form_id = form_id
    fake_credentials = ActiveSupport::OrderedOptions.new
    fake_credentials.kit = fake_kit
    Rails.application.define_singleton_method(:credentials) { fake_credentials }
    yield
  ensure
    Rails.application.singleton_class.remove_method(:credentials)
  end
end
