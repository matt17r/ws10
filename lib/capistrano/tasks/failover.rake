# Failover tasks.
#
# cap bert promote   — make bert the active host (flips CF DNS + enables backups)
# cap bert demote    — make bert passive (disables backups, does NOT flip CF DNS)
# cap ernie failover:take_over — emergency: restore from snapshots and take over
#
# Normal planned failover (maintenance window):
#   1. cap ernie failover:take_over
#   2. Test traffic on ernie
#   3. (bert comes back later — self-demotes via CF check)
#   4. cap bert failover:take_over  (when you want bert to be primary again)

namespace :failover do
  desc "Take over as the active host: restore DB snapshots, deploy, flip CF DNS, enable backups"
  task :take_over do
    invoke "failover:restore_snapshots"
    invoke "deploy"
    invoke "backup:enable"
    invoke "cloudflare:flip_dns"
    invoke "deploy:check_health"
    info "Failover complete. This host is now active."
  end

  desc "Restore the latest incoming DB snapshots into shared/storage (stops puma during swap)"
  task :restore_snapshots do
    on roles(:web) do
      storage_path = shared_path.join("storage")
      incoming = shared_path.join("backups", "incoming")

      execute "mkdir -p #{incoming}"

      PRODUCTION_DATABASES.each do |db_name|
        snapshot = "#{incoming}/#{db_name}.sqlite3"
        unless test("[ -f #{snapshot} ]")
          warn "No snapshot found for #{db_name} — skipping restore (will use existing or fresh DB)."
          next
        end

        info "Restoring #{db_name}..."
        # Verify snapshot integrity before touching live DB
        execute "sqlite3 #{snapshot} 'pragma integrity_check' | grep -q '^ok$'"
        execute "cp #{snapshot} #{storage_path}/#{db_name}.sqlite3"
      end

      info "Restoring Active Storage blobs..."
      blobs_snapshot = "#{incoming}/blobs"
      if test("[ -d #{blobs_snapshot} ]")
        execute "rsync -az --exclude='*.sqlite3' #{blobs_snapshot}/ #{storage_path}/"
      else
        info "No blob snapshot found — skipping."
      end
    end
  end
end

desc "Make this host the active origin: flip CF DNS and enable backups"
task :promote do
  invoke "backup:enable"
  invoke "cloudflare:flip_dns"
  info "#{fetch(:stage)} is now promoted to active."
end

desc "Make this host passive: disable backups (CF DNS unchanged)"
task :demote do
  invoke "backup:disable"
  info "#{fetch(:stage)} is now passive."
end
