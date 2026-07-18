require "test_helper"

class KitClientTest < ActiveSupport::TestCase
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
end
