# Cloudflare DNS management via the CF API.
#
# Requires the following on each server at /home/matthew/apps/ws10/shared/config/cloudflare.env:
#   CF_API_TOKEN=<token with DNS:Edit on the ws10.run zone>
#   CF_ZONE_ID=<zone ID for ws10.run>
#   CF_DNS_RECORD_IDS=ws10.run:<record-id>,www.ws10.run:<record-id>
#
# The tunnel UUID for each host is read from /etc/cloudflared/<host>-tunnel-uuid
# (a plain text file containing just the UUID, written during cloudflared tunnel setup).

namespace :cloudflare do
  desc "Print the current DNS targets for ws10.run and www.ws10.run"
  task :dns_status do
    on roles(:web) do
      env = load_cf_env(shared_path)
      %w[ws10.run www.ws10.run].each do |hostname|
        record_id = find_record_id(env, hostname)
        result = cf_api_get(env, "/zones/#{env["CF_ZONE_ID"]}/dns_records/#{record_id}")
        info "#{hostname} → #{result.dig("result", "content")}"
      end
    end
  end

  desc "Flip ws10.run DNS to point at the current stage's tunnel (called by promote)"
  task :flip_dns do
    on roles(:web) do
      tunnel_uuid = capture("cat #{fetch(:cloudflare_tunnel_uuid_file)}").strip
      target = "#{tunnel_uuid}.cfargotunnel.com"
      env = load_cf_env(shared_path)

      %w[ws10.run www.ws10.run].each do |hostname|
        record_id = find_record_id(env, hostname)
        payload = { type: "CNAME", name: hostname, content: target, proxied: true }.to_json
        cf_api_patch(env, "/zones/#{env["CF_ZONE_ID"]}/dns_records/#{record_id}", payload)
        info "Updated #{hostname} → #{target}"
      end
    end
  end

  # Check whether this host's tunnel is the current CF origin for ws10.run.
  # Returns true/false — called by the backup cron gate, not a user-facing task.
  def self.active_cf_origin?(shared_path_str)
    require "net/http"
    require "json"

    env_file = File.join(shared_path_str, "config", "cloudflare.env")
    return false unless File.exist?(env_file)

    env = parse_env_file(env_file)
    uuid_file = `cat /etc/cloudflared/*-tunnel-uuid 2>/dev/null`.strip
    return false if uuid_file.empty?

    my_target = "#{uuid_file}.cfargotunnel.com"
    record_id = env["CF_DNS_RECORD_IDS"]&.split(",")&.find { |r| r.start_with?("ws10.run:") }&.split(":")&.last
    return false unless record_id

    uri = URI("https://api.cloudflare.com/client/v4/zones/#{env["CF_ZONE_ID"]}/dns_records/#{record_id}")
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{env["CF_API_TOKEN"]}"
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |h| h.request(req) }
    data = JSON.parse(res.body)
    data.dig("result", "content") == my_target
  rescue
    false
  end

  private

  def load_cf_env(shared_path)
    env_file = shared_path.join("config", "cloudflare.env").to_s
    parse_env_file(env_file)
  end

  def parse_env_file(path)
    File.readlines(path, chomp: true).each_with_object({}) do |line, h|
      next if line.strip.empty? || line.start_with?("#")
      k, v = line.split("=", 2)
      h[k.strip] = v&.strip
    end
  end

  def find_record_id(env, hostname)
    env["CF_DNS_RECORD_IDS"]
      .split(",")
      .find { |r| r.start_with?("#{hostname}:") }
      &.split(":")
      &.last or raise "No CF_DNS_RECORD_IDS entry for #{hostname}"
  end

  def cf_api_get(env, path)
    require "net/http"
    require "json"
    uri = URI("https://api.cloudflare.com/client/v4#{path}")
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{env["CF_API_TOKEN"]}"
    req["Content-Type"] = "application/json"
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |h| h.request(req) }
    JSON.parse(res.body)
  end

  def cf_api_patch(env, path, payload)
    require "net/http"
    require "json"
    uri = URI("https://api.cloudflare.com/client/v4#{path}")
    req = Net::HTTP::Patch.new(uri)
    req["Authorization"] = "Bearer #{env["CF_API_TOKEN"]}"
    req["Content-Type"] = "application/json"
    req.body = payload
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |h| h.request(req) }
    result = JSON.parse(res.body)
    raise "CF API error: #{result["errors"]}" unless result["success"]
    result
  end
end
