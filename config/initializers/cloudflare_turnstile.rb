RailsCloudflareTurnstile.configure do |c|
  if ENV["SECRET_KEY_BASE_DUMMY"]
    c.site_key = "DUMMY"
    c.secret_key = "DUMMY"
  else
    c.site_key = Rails.application.credentials.cloudflare_turnstile[:site_key]
    c.secret_key = Rails.application.credentials.cloudflare_turnstile[:secret_key]
  end
  c.fail_open = false
end
