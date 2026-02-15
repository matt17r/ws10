#!/bin/bash
set -euo pipefail

# Only run in Claude Code remote environment (web)
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Install bundler 2.7.2 to match Gemfile.lock
# Cloud environment ships with bundler 4.0.6 which has compatibility issues
if ! gem list bundler -i --version 2.7.2 >/dev/null 2>&1; then
  echo "Installing bundler 2.7.2..."
  gem install bundler -v 2.7.2 --no-document
fi

# Configure bundler version for this project
bundle config set --local version 2.7.2

# Install dependencies
echo "Installing Ruby dependencies..."
bundle _2.7.2_ install --quiet

# Set dummy credentials for cloud environment (tests can run without real credentials)
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo 'export SECRET_KEY_BASE_DUMMY=1' >> "$CLAUDE_ENV_FILE"
fi

echo "Session setup complete!"
