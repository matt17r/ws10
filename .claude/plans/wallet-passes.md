# Digital Wallet Pass Implementation Plan

## Context

Add digital wallet functionality to allow users to download their WS10 barcode as a wallet pass for Apple Wallet and Google Wallet.

### Current State
- Barcodes are generated using the `barby` gem (Code128B format)
- Barcode format: `A{6-digit padded user ID}` (e.g., `A000123`)
- Barcodes are stored as PNG images via Active Storage
- Displayed on user profile page at `app/views/users/show.html.erb:49-54`

### Requirements
1. Generate wallet passes that work cross-platform (Apple Wallet and Google Wallet)
2. Associate passes with three finish locations for automatic suggestions:
   - Bungarribee Park (Doonside Rd & Holbeche Rd, Western Sydney Parklands)
   - Nepean River (Tench Reserve, 163-165 Tench Ave, Penrith NSW 2750)
   - Parramatta Park (Lady Fitzroy Memorial, O'Connell St, Parramatta NSW 2150)
3. One-click download on Profile page, beneath existing barcode image
4. Platform detection to show appropriate download button (Apple vs Google)

### Research Findings

**Cross-Platform Format:**
- Google Wallet now supports Apple's `.pkpass` format (as of March 2024)
- Single `.pkpass` file can work for both platforms
- Some limitations: doesn't work everywhere (some sites require Safari)

**Ruby Gems:**
- `passbook2` - Standalone gem with OpenSSL 3.0 support (recommended)
- `passkit` - Full Rails engine for wallet passes
- `google-apis-walletobjects_v1` - Official Google Wallet API client

---

## Prerequisites

**IMPORTANT:** Before implementing this feature, you must:

1. **Enroll in Apple Developer Program**
   - Cost: $99 USD per year
   - Time: 24-48 hours for approval
   - Required for generating signing certificates
   - Cannot generate `.pkpass` files without these certificates

2. **Have access to a Mac**
   - Needed for Keychain Access to generate CSR and export private keys
   - Required steps can only be done on macOS

**Timeline:** Plan for 2-3 days between enrollment and being able to implement, accounting for Apple's approval process.

---

## Implementation Design

### 1. Gem Selection

**Using: `passbook2` gem**

**Rationale:**
- Lightweight, standalone gem (vs. full Rails engine)
- OpenSSL 3.0 compatible
- No new database models/migrations required
- Generates standard `.pkpass` files that work on both platforms
- Production-tested for ticketing applications

### 2. Architecture

#### New Route
```ruby
# config/routes.rb
resource :user, only: [:show, :edit, :update], path: "profile" do
  get :wallet_pass
end
```

#### Controller Action
```ruby
# app/controllers/users_controller.rb
def wallet_pass
  @user = Current.user

  pass_generator = WalletPassGenerator.new(@user)
  pkpass_data = pass_generator.generate

  send_data pkpass_data,
    type: 'application/vnd.apple.pkpass',
    disposition: 'attachment',
    filename: "ws10-#{@user.barcode_string}.pkpass"
end
```

#### Service Object
```ruby
# app/services/wallet_pass_generator.rb
class WalletPassGenerator
  def initialize(user)
    @user = user
  end

  def generate
    # Create pass with passbook2 gem
    # Add barcode, locations, styling
    # Return binary pkpass data
  end
end
```

#### View Update
Add to `app/views/users/show.html.erb` after the barcode (line 53):

```erb
<div class="mt-3">
  <%= link_to wallet_pass_user_path,
      class: "inline-flex items-center gap-x-1.5 rounded-md bg-primary px-3 py-2 text-sm font-semibold text-white shadow-xs hover:bg-primary-hover" do %>
    <svg class="size-5" fill="currentColor" viewBox="0 0 20 20">
      <path d="M10.75 2.75a.75.75 0 00-1.5 0v8.614L6.295 8.235a.75.75 0 10-1.09 1.03l4.25 4.5a.75.75 0 001.09 0l4.25-4.5a.75.75 0 00-1.09-1.03l-2.955 3.129V2.75z" />
      <path d="M3.5 12.75a.75.75 0 00-1.5 0v2.5A2.75 2.75 0 004.75 18h10.5A2.75 2.75 0 0018 15.25v-2.5a.75.75 0 00-1.5 0v2.5c0 .69-.56 1.25-1.25 1.25H4.75c-.69 0-1.25-.56-1.25-1.25v-2.5z" />
    </svg>
    Add to Wallet
  <% end %>
</div>
```

#### Platform Detection (Progressive Enhancement)
Optional Stimulus controller:

```javascript
// app/javascript/controllers/wallet_button_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent)
    const isAndroid = /Android/.test(navigator.userAgent)

    if (isIOS) {
      this.element.querySelector('span').textContent = 'Add to Apple Wallet'
    } else if (isAndroid) {
      this.element.querySelector('span').textContent = 'Add to Google Wallet'
    }
  }
}
```

### 3. Location Data Strategy

Hardcode venue coordinates directly in the WalletPassGenerator service:

```ruby
# app/services/wallet_pass_generator.rb
VENUE_LOCATIONS = [
  {
    latitude: -33.7634,
    longitude: 150.8319,
    relevantText: "Welcome to WS10 Bungarribee Park!"
  },
  {
    latitude: -33.7542,
    longitude: 150.6719,
    relevantText: "Welcome to WS10 Nepean River!"
  },
  {
    latitude: -33.8115,
    longitude: 151.0014,
    relevantText: "Welcome to WS10 Parramatta Park!"
  }
].freeze
```

**No migration required** - coordinates are static and won't change frequently.

### 4. Pass Structure

**Pass Type:** Store Card

**Key Fields:**
- Primary: User's display name
- Secondary: "WS10 Runner"
- Barcode: Code128 format with value `A{6-digit ID}`

**Design Philosophy:** Keep it simple - focus on the barcode scanning function. No statistics to avoid confusion when stats become outdated.

**Locations (all three venues):**
```ruby
locations = [
  {
    latitude: -33.7634,
    longitude: 150.8319,
    relevantText: "Welcome to WS10 Bungarribee Park!"
  },
  {
    latitude: -33.7542,
    longitude: 150.6719,
    relevantText: "Welcome to WS10 Nepean River!"
  },
  {
    latitude: -33.8115,
    longitude: 151.0014,
    relevantText: "Welcome to WS10 Parramatta Park!"
  }
]
```

### 5. Certificate Requirements

#### Step 1: Enroll in Apple Developer Program

**Prerequisites:**
- Apple ID
- Payment method (credit/debit card)
- $99 USD annual fee

**Enrollment Process:**
1. Visit https://developer.apple.com/programs/
2. Click "Enroll" and sign in with Apple ID
3. Complete entity type (Individual or Organization)
4. Agree to license agreement
5. Complete purchase ($99/year)
6. Wait for approval (typically 24-48 hours)

#### Step 2: Create Pass Type ID

Once enrolled and approved:
1. Sign in to https://developer.apple.com/account
2. Navigate to "Certificates, Identifiers & Profiles"
3. Select "Identifiers" from sidebar
4. Click "+" button → Select "Pass Type IDs"
5. Enter:
   - Description: "WS10 Runner Barcode Pass"
   - Identifier: `pass.com.ws10.runner` (reverse domain notation)
6. Click "Continue" → "Register"

#### Step 3: Generate Certificate Signing Request (CSR)

On your Mac:
1. Open "Keychain Access" application
2. Menu: Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority
3. Fill in:
   - User Email: your email
   - Common Name: "WS10 Pass Signing"
   - CA Email: leave empty
   - Request: "Saved to disk"
4. Save as `PassSigningRequest.certSigningRequest`

#### Step 4: Create Pass Signing Certificate

1. In Apple Developer portal, go to "Certificates"
2. Click "+" → Select "Pass Type ID Certificate"
3. Choose your Pass Type ID (`pass.com.ws10.runner`)
4. Upload the CSR file you created
5. Click "Continue" → Download the certificate (`pass.cer`)

#### Step 5: Download WWDR Certificate

1. Visit https://www.apple.com/certificateauthority/
2. Download "Worldwide Developer Relations - G4" certificate
3. Save as `AppleWWDRCAG4.cer`

#### Step 6: Convert Certificates to PEM Format

```bash
# Convert pass signing certificate
openssl x509 -in pass.cer -inform DER -out pass.pem -outform PEM

# Convert WWDR certificate
openssl x509 -in AppleWWDRCAG4.cer -inform DER -out wwdr.pem -outform PEM

# Export private key from Keychain Access:
# 1. Open Keychain Access
# 2. Find "WS10 Pass Signing" certificate in "My Certificates"
# 3. Expand it to show the private key
# 4. Right-click private key → Export
# 5. Save as certificate.p12 (set a temporary password)

# Convert p12 to PEM (enter the password you set)
openssl pkcs12 -in certificate.p12 -nocerts -out key.pem -nodes
```

#### Step 7: Find Your Team ID

1. In Apple Developer portal, visit "Membership" section
2. Copy your "Team ID" (10-character code like `ABC1234567`)

#### Step 8: Store in Rails Credentials

```bash
# Edit credentials
bin/rails credentials:edit
```

**Add this structure:**
```yaml
wallet_pass:
  certificate: |
    -----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE-----
  wwdr_certificate: |
    -----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE-----
  private_key: |
    -----BEGIN RSA PRIVATE KEY-----
    ...
    -----END RSA PRIVATE KEY-----
  pass_type_id: "pass.com.ws10.runner"
  team_id: "XXXXXXXXXX"
```

**Google Wallet:** No separate certificates needed (reads `.pkpass` directly)

### 6. Testing Strategy

#### Service Tests
```ruby
# test/services/wallet_pass_generator_test.rb
test "generates valid pkpass data" do
  generator = WalletPassGenerator.new(@user)
  pkpass_data = generator.generate

  assert_not_nil pkpass_data
  assert pkpass_data.start_with?("PK") # ZIP signature
end

test "includes all three location coordinates" do
  # Verify pass.json contains 3 location objects
end
```

#### Controller Tests
```ruby
# test/controllers/users_controller_test.rb
test "wallet_pass requires authentication" do
  get wallet_pass_user_url
  assert_redirected_to sign_in_path
end

test "authenticated user can download wallet pass" do
  sign_in_as(users(:one))
  get wallet_pass_user_url

  assert_response :success
  assert_equal 'application/vnd.apple.pkpass', response.content_type
end
```

#### System Tests
```ruby
# test/system/wallet_pass_test.rb
test "user can see add to wallet button on profile" do
  sign_in_as users(:one)
  visit user_url

  assert_selector "a", text: /Add to.*Wallet/i
end
```

### 7. Implementation Sequence

#### Phase 1: Apple Developer Setup (Do First)
1. Enroll in Apple Developer Program ($99/year, 24-48 hour approval)
2. Create Pass Type ID in developer portal
3. Generate CSR using Keychain Access
4. Create Pass Signing Certificate
5. Download WWDR Certificate
6. Convert certificates to PEM format
7. Get Team ID from Membership section
8. Store all credentials in Rails credentials (encrypted)

#### Phase 2: Code Implementation
9. Add `passbook2` gem to Gemfile and run `bundle install`
10. Create `WalletPassGenerator` service with hardcoded coordinates
11. Add `wallet_pass` route to routes.rb
12. Add `wallet_pass` controller action
13. Update profile view with download button

#### Phase 3: Testing & Polish
14. Write service tests (valid pkpass, includes locations)
15. Write controller tests (authentication, file download)
16. Write system test (button visible)
17. Optional: Add Stimulus controller for platform-specific button text
18. Test on actual iOS device (download and add to Apple Wallet)
19. Test on actual Android device (download and add to Google Wallet)

### 8. Certificate Maintenance

**Critical:** Apple certificates expire every 398 days.

Add calendar reminder and monitoring task:
```ruby
# lib/tasks/wallet_pass.rake
namespace :wallet_pass do
  desc "Check certificate expiration"
  task check_certificate: :environment do
    # Parse certificate, check expiration date
    # Send alert if < 30 days remaining
  end
end
```

---

## Trade-offs

### Single `.pkpass` vs Separate Formats
**Chosen:** Single `.pkpass` file

**Pros:**
- Simpler codebase (one generator, one endpoint)
- Works on both platforms
- Lower maintenance burden

**Cons:**
- Android UX slightly worse (requires file manager)
- Can't use Google Wallet-specific features

### Passbook2 vs Passkit Gem
**Chosen:** `passbook2`

**Pros:**
- Lightweight, no database pollution
- Fits Rails philosophy (simple over complex)

**Cons:**
- Manual certificate management
- Can't update passes post-distribution

**Justification:** User barcodes never change, so pass updates are unnecessary.

---

## Critical Files

- `app/services/wallet_pass_generator.rb` - Core pass generation service (new file)
- `app/controllers/users_controller.rb` - Add wallet_pass action
- `app/views/users/show.html.erb` - Add download button (after line 53)
- `config/routes.rb` - Add wallet_pass route
- `config/credentials.yml.enc` - Store Apple certificates and keys (encrypted)

---

## Research Sources

- [passbook2 gem](https://github.com/masukomi/passbook2)
- [Google Wallet pkpass support](https://9to5google.com/2024/04/04/google-wallet-apple-wallet-pass-files-how/)
- [Apple Wallet Passes in Rails](https://avohq.io/blog/apple-wallet-passes-in-rails-apps)
