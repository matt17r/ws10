namespace :deploy do
  desc "Check that CI has passed before deploying main"
  task :check_ci do
    next if fetch(:branch) != "main"

    if %w[true yes y skip].include?(ENV["SKIP_CI"]&.downcase)
      warn "⚠️  SKIP_CI set - bypassing CI check for emergency deploy"
      next
    end

    run_locally do
      branch = fetch(:branch)
      repo = "matt17r/ws10"

      execute(:git, "fetch", "origin", branch)
      sha = capture(:git, "rev-parse", "origin/#{branch}").strip
      info "Checking CI status for commit #{sha[0..7]}..."

      max_attempts = 10
      wait_seconds = 15

      max_attempts.times do |attempt|
        result = capture(:gh, "api", "/repos/#{repo}/commits/#{sha}/check-runs")
        data = JSON.parse(result)
        check_runs = data["check_runs"]

        if check_runs.empty?
          error "No CI checks found for #{sha[0..7]}"
          abort "Deploy aborted: No CI checks configured. Set `SKIP_CI=true` to bypass in emergencies."
        end

        all_completed = check_runs.all? { |run| run["status"] == "completed" }
        failed_runs = check_runs.select { |run| %w[failure timed_out cancelled action_required stale].include?(run["conclusion"]) }

        if all_completed && failed_runs.empty?
          info "✓ CI passed for #{sha[0..7]} (#{check_runs.size} check(s))"
          break
        elsif failed_runs.any?
          error "✗ CI failed for commit #{sha[0..7]}"
          failed_runs.each { |run| error "  - #{run["name"]}: #{run["conclusion"]}" }
          error "View details: https://github.com/#{repo}/commit/#{sha}/checks"
          abort "Deploy aborted: CI checks failed. Set `SKIP_CI=true` to bypass in emergencies."
        elsif attempt < max_attempts - 1
          in_progress = check_runs.count { |run| run["status"] != "completed" }
          warn "CI running (#{in_progress} pending). Will try again in #{wait_seconds}s (attempt #{attempt + 1}/#{max_attempts})"
          sleep wait_seconds
        else
          error "CI did not complete after #{max_attempts} attempts"
          error "View details: https://github.com/#{repo}/commit/#{sha}/checks"
          abort "Deploy aborted: CI checks did not complete in time. Try again once CI has passed or set `SKIP_CI=true` to bypass in emergencies."
        end
      end
    end
  end
end

before "deploy:starting", "deploy:check_ci"
