server "bert", user: "matthew", roles: %w[web]

set :rails_env, "production"

# The other host — used by backup and failover tasks
set :peer_host, "ernie"
set :cloudflare_tunnel_uuid_file, "/etc/cloudflared/bert-tunnel-uuid"
