set :application, "ws10"
set :repo_url, "git@github.com:matt17r/ws10.git"

set :deploy_to, "/home/matthew/ws10"

# Keep the last 5 releases
set :keep_releases, 5

# Files and directories that persist across releases
set :linked_files, %w[config/master.key]
set :linked_dirs, %w[storage log tmp/pids tmp/cache tmp/sockets public/assets]

# Which Ruby version manager to use
set :rbenv_type, :user
set :rbenv_ruby, File.read(".ruby-version").strip

# Bundler: install without dev/test gems, and store vendor/bundle in shared/
set :bundle_without, %w[development test]
set :bundle_path, -> { shared_path.join("bundle") }

# Asset compilation: Tailwind needs a full asset compile
set :assets_prefix, "assets"

# Run db:prepare for all four production databases after each deploy.
# We call db:prepare (not db:migrate) so the first deploy on a fresh server
# creates the schema automatically; subsequent deploys run only pending migrations.
namespace :deploy do
  after :updated, :prepare_databases do
    on roles(:web) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rails, "db:prepare"
          execute :rails, "db:prepare:cache"
          execute :rails, "db:prepare:queue"
          execute :rails, "db:prepare:cable"
        end
      end
    end
  end

  after :published, :restart_puma do
    on roles(:web) do
      execute "systemctl --user restart puma-ws10"
    end
  end

  after :restart_puma, :check_health do
    on roles(:web) do
      sleep 3
      execute "curl -sf http://localhost:3010/up > /dev/null"
    end
  end
end

# Guard: confirm CI is green before deploying (mirrors the old kamal pre-build hook)
before :deploy, :check_ci do
  run_locally do
    branch = fetch(:branch)
    sha = capture("git rev-parse #{branch}").strip

    info "Checking CI status for #{sha}..."
    attempts = 0
    loop do
      status = capture("gh run list --commit #{sha} --json conclusion --jq '.[0].conclusion' 2>/dev/null || true").strip
      case status
      when "success"
        info "CI passed. Proceeding with deploy."
        break
      when "failure", "cancelled"
        error "CI #{status} for #{sha}. Aborting deploy."
        exit 1
      else
        attempts += 1
        if attempts >= 15
          error "CI did not complete after waiting. Aborting."
          exit 1
        end
        info "CI status: '#{status}'. Waiting 10s... (#{attempts}/15)"
        sleep 10
      end
    end
  end
end
