# WS10 Feature Roadmap - Progress Tracker

**Last Updated:** 2026-01-17
**Status:** Helper Mode Feature Complete ✅

---

## Progress Overview

### ✅ Completed Features
- **Feature: Self-Serve Finish Linking** - Users claim finish positions via QR code/token
- **Feature: Badges and Awards** - Implement badges and user badges to incentivise participation
- **Feature: Promote Donations** - Change tone to encourage donations and add various links
- **Feature: Pre-Event Check-In** - Self-service QR code check-in with admin dashboard integration
- **Feature: Helper Mode** - Allow signed-in users to check in someone else or help them claim their finish token (via the other person's barcode)

### 📋 Pending Features
1. Email notification improvements
2. User cleanup tools
3. Kit.com integration
4. Bespoke timing app 🤔
5. Wallet pass download

### 📋 Other Enhancements or Code Tasks
- [x] Mobile improvements for results page
- [ ] Send "2026 update" email via web app and encourage people to sign up for the newsletter. Variations depending on status (run or never run, confirmed or not)

### 📝 Manual Tasks (Non-Code)
- [x] Add events to Running Calendar Australia
- [x] Add event to Strava and ws10 prod
- [x] Add event to Facebook and ws10 prod
- [x] Send January newsletter via Kit.com

---

## Feature: Email Notification Improvements 📋

**Complexity:** LOW
**Priority:** HIGH

### Changes
- Create a volunteer thank you email based on the result/participation ones
- Add a manual approval step before sending result notifications (or some other way to preview results before emails get sent)
- Add more personalisation (just added achievements, perhaps we can add some more stats or awards that are close to being achieved?)
- Include per-event description in emails (this is where I write a little custom blurb for each event that gets displayed at the top of the results page)

### Files to Modify
- `app/models/event.rb` - Change auto-send callback
- `app/mailers/event_mailer.rb` - Add personalisation

---

## Feature: User Cleanup Tools 📋

**Complexity:** MEDIUM
**Priority:** MEDIUM

### Goal
Email inactive users before deletion, admin dashboard for bulk cleanup.

### User Segments
- Never-confirmed (30+ days old)
- Confirmed but never attended (12+ months)

### Implementation
- Admin page listing inactive users
- Bulk actions: Email or Delete
- "We miss you" email template
- User model scope for inactive users

---

## Feature: Kit.com Integration 📋

**Complexity:** HIGH
**Priority:** MEDIUM

### Goal
One-way sync: New WS10 registrations → Kit email list

### Implementation
- Kit API credentials in environment
- User callback after confirmation
- `KitSubscriberService` to handle API calls
- Store Kit subscriber ID on users (for unsubscribe)

---

## Implementation Strategy

### Testing Approach
For each feature:
- Model tests: Validations, business logic, associations
- Controller tests: Happy path + error cases
- System tests: Full user flows
- Integration tests: External services (Stripe) in test mode

### Security Checklist
- Tokens: Secure random generation, no enumeration
- Admin actions: Behind AdminAuthentication
- CSRF: Disabled only for webhooks with signature verification

---

## Feature: Wallet Pass Download 📋

**Complexity:** VERY HIGH
**Priority:** MEDIUM

### Goal
Add digital wallet functionality to allow users to download their WS10 barcode as a wallet pass for Apple Wallet and Google Wallet.

### Implementation
`.claude/plans/wallet-passes.md` contains a fuller exploration

---

## Quick Reference

### Running the App
```bash
bin/dev                    # Start server + Tailwind
bin/rails console         # Rails console
bin/rails test            # Run all tests
bin/rails test:system     # Run system tests
```

### Database
```bash
bin/rails db:migrate                # Run migrations
bin/rails db:rollback               # Rollback last migration
bin/rails db:seed                   # Seed database
```

### Code Quality
```bash
bin/rubocop               # Ruby linter
bin/brakeman              # Security analysis
```

### Deployment
```bash
kamal deploy              # Deploy to production
kamal console             # Production Rails console
```
