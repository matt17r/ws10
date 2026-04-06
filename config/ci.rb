# Run using bin/ci

CI.run do
  step "Lint: Ruby Style", "bin/rubocop -f github"
  step "Security: Ruby static analysis", "bin/brakeman --quiet --no-pager"
  step "Tests: Rails", "bin/rails test:all"
end
