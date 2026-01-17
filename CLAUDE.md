# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Basic Rails Commands
- `bin/dev` - Start the Rails development server and Tailwind watch process (not normally required, the user runs the server constantly)
- `bin/rails console` - Open Rails console for debugging
- `bin/rails generate` - Generate Rails components (models, controllers, migrations)
- `bin/rails db:migrate` - Run database migrations
- `bin/rails db:rollback:primary` - Revert the most recent Rails database migration
- `bin/rails db:seed` - Seed the database with initial data

### Testing
- `bin/rails test` - Run the full test suite, excluding system tests
- `bin/rails test test/models/event_test.rb` - Run a specific test file
- `bin/rails test:system` - Run system tests with Capybara/Selenium
- `bin/rails test:all` - Run the full test suite, including system tests with Capybara/Selenium

### Code Quality
- `bin/brakeman` - Run security analysis
- `bin/rubocop` - Run Ruby style linter (uses rubocop-rails-omakase)

### Deployment (Kamal)
Let the user handle deployment, but here are the commands you might need to suggest to them.

- `kamal setup` - Initial deployment setup
- `kamal deploy` - Deploy application
- `kamal console` - Access production Rails console
- `kamal shell` - SSH into production container
- `kamal logs` - View production logs

## Application Architecture

This is a Rails 8.1 application for managing running events with user registration and results tracking.

### Core Models
- **Event** (`app/models/event.rb`) - Central entity representing running events with date and number. Belongs to a Location. Manages finish positions, times, and results.
- **User** (`app/models/user.rb`) - Handles authentication and user management with email confirmation.
- **Result** (`app/models/result.rb`) - Links users to events with optional completion times.
- **FinishPosition** / **FinishTime** - Track event completion data.
- **Volunteer** / **Role** / **Assignment** - Manage event staffing.
- **Location** (`app/models/location.rb`) - Manages event locations/courses with route details, maps, facilities, and Strava integration.
- **Badge** / **UserBadge** - Achievement badge system with levels (bronze, silver, gold, singular) tracking user milestones.
- **CheckIn** (`app/models/check_in.rb`) - Token-based event check-in system for tracking participant attendance.

### Authentication
Uses a custom authentication system (`app/controllers/concerns/authentication.rb`) with session-based login. No external auth gems like Devise.

### Key Features
- **Email Notifications**: Automatic result/participation emails when events are marked ready
- **Admin Dashboard**: Admin access controlled via `AdminAuthentication` concern
- **Barcode Generation**: Uses `barby` gem for generating barcodes
- **Cloudflare Turnstile**: CAPTCHA integration via `rails_cloudflare_turnstile`

### Frontend Stack
- **Stimulus**: JavaScript framework for Rails
- **Turbo**: For rapid navigation between pages
- **Tailwind CSS**: Styling framework
- **Importmap**: JavaScript module management

### Background Jobs
- **Solid Queue**: Background job processing (runs in Puma process via `SOLID_QUEUE_IN_PUMA`)
- **Solid Cache/Cable**: Rails caching and ActionCable

### Database
- **SQLite**: Used in all environments with Active Storage for file uploads
- **Migrations**: Located in `db/migrate/` with models for users, events, results, etc.

### Testing Structure
- **Fixtures**: Test data in `test/fixtures/`
- **System Tests**: Browser-based tests in `test/system/`
- **Model/Controller Tests**: Unit tests in respective directories
- **Mailer Previews**: Located in `test/mailers/previews/`

### Deployment Notes
- Uses Kamal for containerized deployment
- Deployed to custom server (svr-02) with Cloudflare proxy
- Assets are fingerprinted and served via Propshaft
- Production uses persistent volumes for SQLite and Active Storage

## Common Patterns

### Controllers
All controllers inherit from `ApplicationController` which includes `Authentication` concern. Use `allow_unauthenticated_access` to skip authentication on specific actions. Ask or confirm before skipping authentication.

### Models
Models follow standard Rails patterns with Active Record. The `Event` model contains the main business logic for result notifications and user management.

### Email System
Event-related emails are triggered automatically when an event's status changes to `finalised`. Uses Action Mailer with deliver_later for background processing.

### Admin Features
Admin functionality is separated into `app/controllers/admin/` namespace with `AdminAuthentication` concern for access control.

## Development Best Practices

### Database Migrations
**Always test migration reversibility**: After creating and running a new migration with `bin/rails db:migrate`, immediately test that it can be rolled back with `bin/rails db:rollback:primary`, then re-run `bin/rails db:migrate` to ensure the migration works in both directions. This prevents production deployment issues.

### Test Coverage
**Always include tests for new code**: Always write tests to cover new code or changes to existing code, even if that code wasn't previously tested. Write the test first and confirm it fails before writing the code.

### Test Expansion
**Ask whether to look for additional bugs**: If you add a test and fix 1 bug, it may be a sign that there are other similar bugs lurking. Once you've fixed a bug and the tests are passing again, ask me if I want you to search the codebase for similar bugs.

**Ask whether to add additional tests**: If you add a new test to one method/action/controller, ask me if I want you to find similar actions or codepaths that are still untested.

### Test Setup
**Keep shared setup minimal**: Shared setup blocks should be as minimal as possible (preferably empty). Test setup should be explicit and local to each individual test for clarity and maintainability.

### Test Coverage Strategy
**Layer tests by scope and thoroughness**: System tests should focus on happy path user flows. Controller tests should cover the happy path and common error scenarios. Model tests should be very thorough, covering happy path, common errors, edge cases, and business logic validation.

### Dependencies
**Avoid introducing new dependencies**: Where possible, use gems that are already included (can be dependencies of explicitly required gems) to accomplish tasks. Ask before introducing a new gem. Be extra cautious before before introducing new JavaScript dependencies. Don't introduce a JavaScript dependency when 20-50 lines of vanilla JavaScript will fill the need.

### Progressive Enhancement
**Build vanilla-first, enhance with JavaScript**: Always implement features to work completely without JavaScript first using standard Rails patterns (forms, links, redirects). Then add Stimulus controllers as progressive enhancements to improve the user experience for those with JavaScript enabled. This ensures accessibility and graceful degradation.

### Data Integrity
**Use database constraints alongside Rails validations**: Add database-level constraints (NOT NULL, foreign key constraints, unique indexes) in migrations for critical data integrity, in addition to Rails model validations. Test these constraints separately from model validations in your test suite to ensure they work at the database level.

### Security
**Respect Rails' built-in protections**: Never bypass or work around Rails' built-in security features (CSRF protection, parameter filtering, SQL injection protection, etc.) without explicit approval. When implementing any feature that might have security implications, ask for review and confirmation before proceeding.

### Code Clarity
**Avoid comments in favour of clear code**: Instead of writing comments, use clearer variable names, extract methods with descriptive names, or refactor code to be self-documenting. Comments should be extremely rare and only used when the "why" cannot be expressed through code itself.
- The linting command is `bin/rubocop -f github`
