set :application, "ws10"
set :repo_url, "git@github.com:matt17r/ws10.git"

set :deploy_to, "/home/matthew/ws10"

def branch_name(default_branch)
  branch = ENV.fetch("BRANCH", default_branch)
  branch == "." ? `git rev-parse --abbrev-ref HEAD`.chomp : branch
end

set :branch, branch_name("main")

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
      execute "for i in $(seq 1 15); do curl -sf http://localhost:3010/up > /dev/null && exit 0; sleep 1; done; exit 1"
    end
  end
end
