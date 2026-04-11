# Database backup tasks.
#
# Backups are SQLite online snapshots (.backup) rsynced to the peer host.
# Active Storage blob directories are rsynced directly (safe to copy live).
#
# The backup gate:
#   1. Check shared/config/backup_enabled — exit silently if false/missing.
#   2. Check Cloudflare DNS — if this host's tunnel isn't the current origin,
#      self-demote (write backup_enabled=false) and exit.
#   3. Proceed with backup.

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
      peer = fetch(:peer_host)
      storage_path = shared_path.join("storage")
      incoming_path = "/home/matthew/apps/ws10/shared/backups/incoming"

      enabled_flag = shared_path.join("config", "backup_enabled").to_s
      unless test("[ -f #{enabled_flag} ] && grep -q true #{enabled_flag}")
        info "Backup not enabled on this host — skipping."
        next
      end

      info "Verifying Cloudflare origin..."
      unless test("#{current_path}/script/cf_active_check.rb 2>/dev/null")
        info "This host is not the active CF origin — self-demoting and skipping backup."
        execute "echo false > #{enabled_flag}"
        next
      end

      PRODUCTION_DATABASES.each do |db_name|
        db_file = storage_path.join("#{db_name}.sqlite3")
        tmp_bak = "/tmp/ws10_backup_#{db_name}.sqlite3"

        info "Snapshotting #{db_name}..."
        execute "sqlite3 #{db_file} \".backup #{tmp_bak}\""

        info "Shipping #{db_name} to #{peer}..."
        execute "rsync -az --partial #{tmp_bak} #{peer}:#{incoming_path}/#{db_name}.sqlite3.new"
        execute "ssh #{peer} 'mv #{incoming_path}/#{db_name}.sqlite3.new #{incoming_path}/#{db_name}.sqlite3'"
        execute "rm -f #{tmp_bak}"
      end

      info "Syncing Active Storage blobs to #{peer}..."
      # Sync only the blob subdirectories (2-char hash dirs), not the SQLite files
      execute "rsync -az --delete --exclude='*.sqlite3' #{storage_path}/ #{peer}:#{incoming_path}/blobs/"

      info "Backup complete."
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

      incoming = "/home/matthew/apps/ws10/shared/backups/incoming"
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
