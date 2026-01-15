# WS10: Website and admin for Western Sydney 10 running events

A Rails 8.0 application for managing running events with user registration, results tracking, and comprehensive admin tools.

## Features

- **Event Management**: Create and manage monthly 10km running events
- **User Registration**: Custom authentication with email confirmation
- **Results Tracking**: Record finish positions, times, and generate participant results
- **Admin Dashboard**: Comprehensive user and event management interface
- **Email Notifications**: Automatic result notifications when events are marked ready
- **Volunteer Management**: Track volunteer assignments and roles
- **Barcode System**: Generate unique barcodes for participant tracking

## Architecture

### Tech Stack

- **Backend**: Rails 8.0 with Ruby 3.3.4
- **Database**: SQLite (all environments)
- **Frontend**: Stimulus, Turbo, Tailwind CSS, Importmap
- **Background Jobs**: Solid Queue (runs in Puma process via `SOLID_QUEUE_IN_PUMA`)
- **File Storage**: Active Storage with SQLite
- **Authentication**: Custom session-based system (no Devise)
- **Security**: Cloudflare Turnstile CAPTCHA integration

### Core Models

- **Event** - Central entity representing running events with date, location, and number. Manages finish positions, times, and results
- **User** - Handles authentication and user management with email confirmation. Links to results and volunteer assignments
- **Result** - Links users to events with optional completion times and finish positions
- **FinishPosition** / **FinishTime** - Track event completion data separately for flexible result management
- **Volunteer** / **Role** / **Assignment** - Manage event staffing and user permissions (Administrator, Organiser)

### Key Features

- **Email Notifications**: Automatic result/participation emails when events are marked ready
- **Admin Dashboard**: Admin access controlled via `AdminAuthentication` concern
- **Progressive Enhancement**: Features work without JavaScript, enhanced with Stimulus controllers
- **Responsive Design**: Mobile-first interface using Tailwind CSS

## Development

### Getting Started

1. Clone the repository
2. Install dependencies: `bundle install`
3. Setup database: `bin/rails db:setup`
4. Start development server: `bin/dev`
5. Visit `http://localhost:3010`

### Development Setup with puma-dev

For a better development experience with custom domains:

1. Install puma-dev: `brew install puma/puma/puma-dev`
2. Setup system domains: `sudo puma-dev -setup`
3. Install as service **(with localhost domain)**: `puma-dev -install -d localhost`
4. Configure project: `echo 3010 > ~/.puma-dev/ws10`
5. Start development server: `bin/dev`
6. Visit `https://ws10.localhost` (automatic HTTPS!)

**Benefits**: Clean URLs, automatic SSL certificates, multiple projects without port conflicts

### Development Commands

- `bin/dev` - Start Rails server and Tailwind watch process
- `bin/rails console` - Open Rails console
- `bin/rails test` - Run test suite (excluding system tests)
- `bin/rails test:system` - Run system tests with Capybara/Selenium
- `bin/rails test:all` - Run full test suite including system tests
- `bin/brakeman` - Run security analysis
- `bin/rubocop` - Run Ruby style linter

### Database Management

#### Production Data in Development

To work with real production data in development:

```bash
# Two-step process:
bin/rails db:dump      # Download SQL dump from production (creates tmp/db.sql)
bin/rails db:restore   # Restore from SQL dump to development

# Or combined:
bin/rails db:dump && bin/rails db:restore

# Restore development database from backup if needed
bin/rails db:restore_dev_backup
```

**Safety Features:**
- Automatically backs up current development database before restore
- Timestamped backups stored in `tmp/development_backup_YYYYMMDD_HHMMSS.sqlite3`
- Recovery available via `db:restore_dev_backup` task

**Requirements:**
- SSH access to production server (svr-02) using key-based authentication
- Production server configured in Kamal deployment

### Emails

Email functionality uses Action Mailer with `deliver_later` for background processing. Event-related emails are triggered automatically when `results_ready` is set to true on an Event.

**Development**: Emails are blocked (`delivery_method = :test`) - no emails sent
**Production**: Uses configured SMTP settings for delivery

### Credentials

Uses Rails encrypted credentials for sensitive configuration. The application includes:

- Database configuration
- Email SMTP settings
- Cloudflare Turnstile keys
- Any API keys or secrets

**Note**: Never commit actual credentials to the repository.

### Upgrading

When upgrading Rails or dependencies:

1. Update `Gemfile`
2. Run `bundle update`
3. Run database migrations: `bin/rails db:migrate`
4. Test migration reversibility: `bin/rails db:rollback` then `bin/rails db:migrate`
5. Run full test suite: `bin/rails test:all`
6. Update any deprecated code based on upgrade guides

## Deployment

Deployed using Kamal to a custom server with Cloudflare proxy:

### Prerequisites

- SSH access via public key to hostname specified in `config/deploy.yml` (under `servers` -> `web`)
- Set `KAMAL_REGISTRY_PASSWORD` environment variable (`set -Ux KAMAL_REGISTRY_PASSWORD your_password` in fish shell)
- Cloudflare tunnel setup pointing to hostname specified in `config/deploy.yml` (under `proxy` -> `host`)
- GitHub CLI (`gh`) installed and authenticated for CI status checks

### Deploy Commands

- `kamal setup` - Initial deployment setup
- `kamal deploy` - Deploy application updates
- `kamal console` - Access production Rails console
- `kamal shell` - SSH into production container
- `kamal logs` - View production logs

### Deployment Safety Checks

A `pre-build` hook runs before (production) builds to prevent accidental deployments:

- **Branch Check**: Must deploy from `main` branch
- **Push Check**: All commits must be pushed to origin
- **CI Check**: GitHub Actions must pass for the commit being deployed

The CI check will:
- Wait up to 2.5 minutes for in-progress checks to complete
- Fail if any checks fail or don't complete in time
- Show which checks failed and provide a link to view details

To bypass all safety checks (branch, push, and CI), use:
```bash
FORCE_DEPLOY=unsafe_force kamal deploy
```

### Production Environment

- Uses persistent volumes for SQLite database and Active Storage
- Assets fingerprinted and served via Propshaft
- Background jobs processed via Solid Queue
- SSL handled by Cloudflare

## Security

### Authentication & Authorization

- **Custom Authentication**: Session-based login system without external dependencies
- **Email Confirmation**: Users must confirm email addresses before full access
- **Role-Based Access**: Administrator and Organiser roles with different permission levels
- **Admin Protection**: Admin routes protected by `AdminAuthentication` concern
- **Self-Protection**: Users cannot delete themselves or remove their own admin roles

### Security Measures

- **CSRF Protection**: Rails built-in CSRF protection enabled
- **SQL Injection Protection**: Parameterized queries and Active Record protections
- **CAPTCHA Integration**: Cloudflare Turnstile prevents automated abuse
- **Secure Headers**: Standard Rails security headers configured
- **Password Security**: Uses `has_secure_password` with bcrypt hashing
- **Session Security**: Secure session configuration with appropriate timeouts

### Best Practices

- **No Secrets in Code**: All sensitive data stored in Rails encrypted credentials
- **Parameter Filtering**: Sensitive parameters filtered from logs
- **Input Validation**: Comprehensive model validations and parameter permits
- **Database Constraints**: Database-level constraints complement Rails validations
- **Security Scanning**: Regular Brakeman security analysis in development
