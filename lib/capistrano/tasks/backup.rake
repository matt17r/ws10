# Database backup tasks.
#
# Backups are SQLite online snapshots (.backup) rsynced to the peer host.
# Active Storage blob directories are rsynced directly (safe to copy live).
#
# The ship logic (including the backup_enabled + Cloudflare origin gate)
# lives in script/ship_backups, which the ws10-backup systemd user timer
# runs hourly on each host; backup:ship just invokes it remotely.

PRODUCTION_DATABASES = %w[
  production
  production_cache
  production_queue
  production_cable
].freeze

namespace :backup do
  desc "Snapshot the 4 SQLite DBs and rsync them + Active Storage to the peer host"
  task :ship do
    on roles(:web) do
      execute "#{current_path}/script/ship_backups"
    end
  end

  desc "Enable backups on this host (called by promote)"
  task :enable do
    on roles(:web) do
      flag = shared_path.join("config", "backup_enabled")
      execute "echo true > #{flag}"
      info "Backups enabled on #{fetch(:server_name, "this host")}."
    end
  end

  desc "Disable backups on this host (called by demote)"
  task :disable do
    on roles(:web) do
      flag = shared_path.join("config", "backup_enabled")
      execute "echo false > #{flag}"
      info "Backups disabled on #{fetch(:server_name, "this host")}."
    end
  end

  desc "Print backup status (enabled flag + timestamp of last incoming snapshot)"
  task :status do
    on roles(:web) do
      flag = shared_path.join("config", "backup_enabled")
      enabled = test("[ -f #{flag} ] && grep -q true #{flag}") ? "enabled" : "disabled"
      info "Backups on this host: #{enabled}"

      incoming = "#{fetch(:deploy_to)}/shared/backups/incoming"
      PRODUCTION_DATABASES.each do |db_name|
        f = "#{incoming}/#{db_name}.sqlite3"
        if test("[ -f #{f} ]")
          ts = capture("stat -c '%y' #{f} 2>/dev/null || stat -f '%Sm' #{f}").strip
          info "  #{db_name}: last snapshot #{ts}"
        else
          info "  #{db_name}: no snapshot yet"
        end
      end
    end
  end
end
