class KitClient
  BASE_URL = "https://api.kit.com/v4"

  def subscribe(email:, name:)
    body = { email_address: email, first_name: name.split.first }
    response = post("/subscribers", body)
    response["subscriber"]
  end

  def unsubscribe(subscriber_id:)
    response = delete("/subscribers/#{subscriber_id}")
    response
  end

  def find_subscriber(email:)
    response = get("/subscribers", { email_address: email })
    subscribers = response["subscribers"]
    subscribers.first if subscribers&.any?
  end

  def list_subscribers
    subscribers = []
    cursor = nil

    loop do
      params = { status: "active", per_page: 1000 }
      params[:after] = cursor if cursor

      response = get("/subscribers", params)
      batch = response["subscribers"] || []
      subscribers.concat(batch)

      cursor = response.dig("pagination", "end_cursor")
      break unless response.dig("pagination", "has_next_page")
    end

    subscribers
  end

  def add_tag(subscriber_id:, tag_id:)
    post("/tags/#{tag_id}/subscribers", { subscriber_id: subscriber_id })
  end

  private

  def get(path, params = {})
    uri = URI("#{BASE_URL}#{path}")
    uri.query = URI.encode_www_form(params) if params.any?
    request = Net::HTTP::Get.new(uri)
    perform(uri, request)
  end

  def post(path, body = {})
    uri = URI("#{BASE_URL}#{path}")
    request = Net::HTTP::Post.new(uri)
    request.body = body.to_json
    perform(uri, request)
  end

  def delete(path)
    uri = URI("#{BASE_URL}#{path}")
    request = Net::HTTP::Delete.new(uri)
    perform(uri, request)
  end

  def perform(uri, request)
    request["Authorization"] = "Bearer #{api_secret}"
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      response = http.request(request)
      JSON.parse(response.body) if response.body.present?
    end
  end

  def api_secret
    Rails.application.credentials.kit&.fetch(:api_secret) ||
      raise("Kit API secret not configured")
  end
end
