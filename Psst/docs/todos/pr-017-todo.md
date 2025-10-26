# PR-017 TODO — Fastlane Deployment Setup

**Branch**: `feat/pr-017-fastlane-setup`
**Source PRD**: `Psst/docs/prds/pr-017-prd.md`
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

**Questions**:
- Confirm Apple Developer Program membership is active
- Confirm which certificate storage method: GitHub repo or Google Cloud Storage?

**Assumptions**:
- Apple Developer Program account exists and is active
- Team has access to create App Store Connect API keys
- Using GitHub repository for Match certificate storage (simpler for small team)
- Default iOS simulator "Vanes" is available for testing
- Team uses Homebrew for package management

---

## 1. Setup

- [ ] Create branch `feat/pr-017-fastlane-setup` from develop
- [ ] Read PRD thoroughly: `Psst/docs/prds/pr-017-prd.md`
- [ ] Read `Psst/agents/shared-standards.md` for deployment patterns
- [ ] Verify Xcode project builds successfully before Fastlane setup
- [ ] Confirm Homebrew installed: `brew --version`
- [ ] Confirm access to Apple Developer account and App Store Connect

**Test Gate**: Xcode builds app successfully with default signing configuration

---

## 2. Install Fastlane CLI

- [ ] Install Fastlane via Homebrew: `brew install fastlane`
- [ ] Verify installation: `fastlane --version` (should show version 2.x)
- [ ] Navigate to project root directory
- [ ] Initialize Fastlane: `fastlane init`
  - Select option 4: "Manual setup"
  - This creates `fastlane/` directory with basic `Fastfile` and `Appfile`

**Test Gate**: `fastlane/Fastfile` and `fastlane/Appfile` created successfully

---

## 3. Configure Appfile

Update `fastlane/Appfile` with app-specific configuration:

- [ ] Open `fastlane/Appfile`
- [ ] Add app identifier: `app_identifier("com.yourcompany.Psst")`
- [ ] Add Apple ID: `apple_id("your-apple-id@example.com")`
- [ ] Add team ID: `team_id("YOUR_TEAM_ID")` (find in Apple Developer portal)
- [ ] Save file

**Test Gate**: Appfile contains valid app identifier and team ID

---

## 4. Create App Store Connect API Key

- [ ] Log in to App Store Connect (https://appstoreconnect.apple.com)
- [ ] Navigate to Users and Access → Keys → App Store Connect API
- [ ] Click "+" to create new API key
- [ ] Name: "Fastlane CI"
- [ ] Access: "Developer" role
- [ ] Download `.p8` private key file (only available once!)
- [ ] Note the **Key ID** and **Issuer ID** (shown on keys page)
- [ ] Move `.p8` file to `fastlane/AuthKey_[KEY_ID].p8`
- [ ] Verify file exists and is not in git tracking

**Test Gate**: `.p8` file exists in `fastlane/` directory, Key ID and Issuer ID documented

---

## 5. Create Environment Variables File

- [ ] Create `fastlane/.env.example` template with required variables:
  ```bash
  # App Store Connect API Authentication
  APP_STORE_CONNECT_API_KEY_ID="ABC123XYZ"
  APP_STORE_CONNECT_ISSUER_ID="12345678-90ab-cdef-1234-567890abcdef"
  APP_STORE_CONNECT_API_KEY_PATH="./fastlane/AuthKey_ABC123XYZ.p8"

  # Match Certificate Storage
  MATCH_PASSWORD="your-super-secret-password"
  MATCH_GIT_URL="git@github.com:your-org/psst-certificates.git"
  ```
- [ ] Copy to `fastlane/.env` and fill in actual values
- [ ] Replace placeholders with real Key ID, Issuer ID, and API key path
- [ ] Generate strong Match password (save in team password manager)
- [ ] Create private GitHub repo `psst-certificates` for Match storage
- [ ] Add `MATCH_GIT_URL` pointing to the new repo

**Test Gate**: `.env` file created with real values, `.env.example` has placeholder examples

---

## 6. Update .gitignore

Add Fastlane-specific ignore rules to prevent sensitive files from being committed:

- [ ] Open `.gitignore` in project root
- [ ] Add the following lines:
  ```
  # Fastlane
  fastlane/report.xml
  fastlane/Preview.html
  fastlane/screenshots
  fastlane/test_output
  fastlane/.env
  fastlane/AuthKey_*.p8
  *.ipa
  *.dSYM.zip
  ```
- [ ] Verify `fastlane/.env` and `AuthKey_*.p8` are git-ignored
- [ ] Run `git status` to confirm no sensitive files appear

**Test Gate**: `git status` does not show `.env` or `.p8` files as untracked

---

## 7. Initialize Match (Certificate Management)

- [ ] Run `fastlane match init` from project root
- [ ] Select storage mode: "git"
- [ ] Enter Match git URL: Value from `MATCH_GIT_URL` in `.env`
- [ ] This creates `fastlane/Matchfile` configuration
- [ ] Edit `Matchfile` to reference environment variables:
  ```ruby
  git_url(ENV["MATCH_GIT_URL"])
  storage_mode("git")
  type("appstore")
  app_identifier(["com.yourcompany.Psst"])
  username("your-apple-id@example.com")
  ```
- [ ] Generate certificates: `fastlane match appstore` (first time only)
- [ ] Enter Match password when prompted (from `.env`)
- [ ] Verify certificates stored in `psst-certificates` GitHub repo

**Test Gate**: Certificates generated and pushed to Match storage repo, Keychain contains App Store distribution certificate

---

## 8. Create Fastfile Lanes - Beta Lane

Update `fastlane/Fastfile` with automated deployment lanes:

- [ ] Open `fastlane/Fastfile`
- [ ] Add `beta` lane for TestFlight deployment:
  ```ruby
  default_platform(:ios)

  platform :ios do
    desc "Deploy a new beta build to TestFlight"
    lane :beta do
      # 1. Ensure clean git state
      ensure_git_status_clean

      # 2. Increment build number
      increment_build_number(xcodeproj: "Psst/Psst.xcodeproj")

      # 3. Sync certificates/profiles from Match
      match(
        type: "appstore",
        readonly: true,
        app_identifier: "com.yourcompany.Psst"
      )

      # 4. Build the app
      build_app(
        scheme: "Psst",
        export_method: "app-store",
        output_directory: "./build",
        output_name: "Psst.ipa"
      )

      # 5. Upload to TestFlight
      upload_to_testflight(
        api_key_path: ENV["APP_STORE_CONNECT_API_KEY_PATH"],
        skip_waiting_for_build_processing: true,
        distribute_external: false,
        changelog: "New beta build from Fastlane"
      )

      # 6. Commit build number bump
      commit_version_bump(
        message: "Bump build number [skip ci]",
        xcodeproj: "Psst/Psst.xcodeproj"
      )

      # 7. Success notification
      puts "✅ Successfully uploaded to TestFlight!"
    end
  end
  ```
- [ ] Verify lane syntax with `fastlane lanes`

**Test Gate**: `fastlane lanes` lists `beta` lane without syntax errors

---

## 9. Create Fastfile Lanes - Release Lane

- [ ] Add `release` lane to `Fastfile`:
  ```ruby
  desc "Deploy a new production build to App Store"
  lane :release do
    # 1. Ensure clean git state
    ensure_git_status_clean

    # 2. Sync certificates (App Store distribution)
    match(
      type: "appstore",
      readonly: true,
      app_identifier: "com.yourcompany.Psst"
    )

    # 3. Build the app
    build_app(
      scheme: "Psst",
      export_method: "app-store",
      output_directory: "./build",
      output_name: "Psst.ipa"
    )

    # 4. Upload to App Store (manual release)
    upload_to_app_store(
      api_key_path: ENV["APP_STORE_CONNECT_API_KEY_PATH"],
      skip_metadata: true,
      skip_screenshots: true,
      submit_for_review: false,
      force: true
    )

    puts "✅ Successfully uploaded to App Store. Complete submission in App Store Connect."
  end
  ```

**Test Gate**: `fastlane lanes` lists both `beta` and `release` lanes

---

## 10. Create Fastfile Lanes - Test Lane

- [ ] Add `test` lane to `Fastfile`:
  ```ruby
  desc "Run unit and UI tests"
  lane :test do
    run_tests(
      scheme: "Psst",
      devices: ["Vanes"],
      clean: true,
      code_coverage: true,
      output_directory: "./test_output"
    )
  end
  ```

**Test Gate**: `fastlane test` runs (may fail if no tests exist yet, but should execute)

---

## 11. Create Fastfile Lanes - Screenshots Lane (Optional)

- [ ] Add `screenshots` lane to `Fastfile`:
  ```ruby
  desc "Generate App Store screenshots"
  lane :screenshots do
    capture_screenshots(
      scheme: "PsstUITests",
      devices: ["iPhone 15 Pro", "iPad Pro (12.9-inch) (6th generation)"],
      languages: ["en-US"],
      output_directory: "./fastlane/screenshots",
      clear_previous_screenshots: true
    )
  end
  ```

**Test Gate**: Lane added to Fastfile (execution tested later when UI tests exist)

---

## 12. Create Fastlane Documentation

- [ ] Create `fastlane/README.md` with comprehensive setup guide:
  - **Prerequisites**: Xcode, Homebrew, Apple Developer Program membership
  - **Installation Steps**: Install Fastlane, configure API key, run Match
  - **Lane Descriptions**: `beta`, `release`, `test`, `screenshots`
  - **Troubleshooting**: Common errors and solutions
  - **Environment Variables**: Required `.env` variables with descriptions
- [ ] Include example commands:
  ```bash
  # Deploy to TestFlight
  fastlane beta

  # Deploy to App Store (manual submission)
  fastlane release

  # Run tests
  fastlane test

  # Generate screenshots
  fastlane screenshots

  # Sync certificates (new team member setup)
  fastlane match appstore --readonly
  ```
- [ ] Document Match setup for new developers
- [ ] Add API key creation instructions with screenshots

**Test Gate**: README.md exists with all required sections, commands are accurate

---

## 13. Update Main README

- [ ] Open main `README.md` in project root
- [ ] Add "Deployment" section with link to Fastlane README:
  ```markdown
  ## Deployment

  This project uses Fastlane for automated iOS deployments.

  ### Quick Start
  - **Deploy to TestFlight**: `fastlane beta`
  - **Deploy to App Store**: `fastlane release`

  For detailed setup instructions, see [fastlane/README.md](fastlane/README.md).
  ```
- [ ] Save file

**Test Gate**: Main README includes deployment section with Fastlane reference

---

## 14. Manual Testing - Beta Deployment (Happy Path)

**Before testing**: Ensure Xcode project has no uncommitted changes (Fastlane requires clean git state).

- [ ] Open terminal in project root
- [ ] Run: `fastlane beta`
- [ ] Observe terminal output for each step:
  - ✅ Git status clean
  - ✅ Build number incremented
  - ✅ Match synced certificates
  - ✅ Xcode built IPA successfully
  - ✅ Uploaded to TestFlight
  - ✅ Build number commit created
- [ ] Wait 2-5 minutes for upload to complete
- [ ] Log in to App Store Connect → TestFlight → iOS builds
- [ ] Verify new build appears with incremented build number
- [ ] Wait 5-10 minutes for Apple to process build
- [ ] Confirm build shows "Ready to Test" status

**Test Gate**: Build appears in TestFlight with status "Ready to Test", no errors in terminal

---

## 15. Manual Testing - Edge Case: First-Time Setup

Simulate new developer joining the team:

- [ ] On a different machine (or delete certificates from Keychain):
  - Delete App Store distribution certificate from Keychain Access
  - Delete provisioning profiles from `~/Library/MobileDevice/Provisioning Profiles/`
- [ ] Clone project fresh
- [ ] Create `fastlane/.env` from `.env.example` with correct values
- [ ] Run: `fastlane match appstore --readonly`
- [ ] Verify Match downloads and installs certificates
- [ ] Run: `fastlane beta`
- [ ] Verify deployment succeeds without manual certificate installation

**Test Gate**: New developer can deploy after running `fastlane match`, no manual Keychain setup required

---

## 16. Manual Testing - Error Handling: Invalid API Key

- [ ] Temporarily rename `.env` to `.env.backup`
- [ ] Run: `fastlane beta`
- [ ] Expected error: "APP_STORE_CONNECT_API_KEY_PATH not found"
- [ ] Verify error message is clear and mentions checking `.env` file
- [ ] Restore `.env` from backup
- [ ] Run `fastlane beta` again to verify it works

**Test Gate**: Clear error message when API key missing, deployment succeeds after fixing

---

## 17. Manual Testing - Error Handling: Expired Certificate

*Note: Only test if certificate is actually expiring soon, otherwise skip.*

- [ ] If certificate is within 30 days of expiration:
  - Run: `fastlane match nuke distribution` (deletes existing cert)
  - Run: `fastlane match appstore` (generates new cert)
  - Verify new certificate created and uploaded to Match repo
  - Run: `fastlane beta` to verify deployment with new cert

**Test Gate**: New certificate generated successfully, deployment continues

---

## 18. Manual Testing - Performance Check

- [ ] Measure full deployment time from `fastlane beta` start to completion:
  - Start timer when command starts
  - Stop timer when "Successfully uploaded to TestFlight" appears
  - Expected: < 10 minutes total (5 min build + 3 min upload + overhead)
- [ ] Measure Match certificate sync time:
  - Run: `fastlane match appstore --readonly`
  - Expected: < 10 seconds

**Test Gate**: Full deployment < 10 minutes, Match sync < 10 seconds

---

## 19. Code Quality & Documentation

- [ ] Review all Fastlane configuration files for typos
- [ ] Verify all environment variables in `.env.example` have clear descriptions
- [ ] Check `fastlane/README.md` for completeness:
  - [ ] Prerequisites listed
  - [ ] Setup steps documented
  - [ ] All lanes explained
  - [ ] Troubleshooting section included
- [ ] Verify `.gitignore` excludes all sensitive files
- [ ] Run `git status` to ensure no secrets are tracked

**Test Gate**: All documentation clear, no sensitive files in git

---

## 20. Acceptance Gates Verification

Verify all gates from PRD Section 12:

- [ ] **Gate 1**: Developer runs `fastlane beta` → App uploads to TestFlight without manual intervention ✅
- [ ] **Gate 2**: New team member runs `fastlane match` → Certificates install automatically ✅
- [ ] **Gate 3**: API key authentication works without 2FA prompts ✅
- [ ] **Gate 4**: Invalid API key shows clear error message ✅
- [ ] **Gate 5**: Build number auto-increments and commits to git ✅
- [ ] **Gate 6**: Full deployment completes in < 10 minutes ✅

**Test Gate**: All acceptance gates from PRD pass

---

## 21. Documentation & PR Preparation

- [ ] Add inline comments to complex Fastfile lane logic
- [ ] Verify `fastlane/README.md` is comprehensive
- [ ] Ensure main `README.md` links to Fastlane documentation
- [ ] Create `.env.example` with clear variable descriptions
- [ ] Document Match password storage location (team password manager)
- [ ] Add troubleshooting section for common errors:
  - Invalid API key
  - Match password incorrect
  - Certificate expired
  - Network timeout during upload
  - Build number conflict

**Test Gate**: Documentation complete, new developer can follow setup guide

---

## 22. Create PR Description

- [ ] Verify with user before creating PR
- [ ] Create PR targeting `develop` branch
- [ ] Use the following PR description template:

```markdown
# PR #017: Fastlane Deployment Setup

## Summary
Implements automated iOS deployment pipeline using Fastlane with App Store Connect API authentication for streamlined TestFlight and App Store releases.

## Changes
- ✅ Installed Fastlane CLI and configured project
- ✅ Created Fastfile with `beta`, `release`, `test`, `screenshots` lanes
- ✅ Configured App Store Connect API key authentication (no 2FA required)
- ✅ Set up Match for automated code signing certificate management
- ✅ Added `.env` configuration for secure credential storage
- ✅ Updated `.gitignore` to exclude sensitive files
- ✅ Created comprehensive documentation in `fastlane/README.md`
- ✅ Updated main README with deployment instructions

## How to Use
**Deploy to TestFlight:**
```bash
fastlane beta
```

**Deploy to App Store:**
```bash
fastlane release
```

**Run Tests:**
```bash
fastlane test
```

**New Team Member Setup:**
```bash
# 1. Create .env from .env.example
# 2. Add Match password from team password manager
# 3. Sync certificates
fastlane match appstore --readonly
```

## Testing Completed
- [x] Happy Path: `fastlane beta` uploads to TestFlight successfully
- [x] Edge Case: New developer can sync certificates via Match
- [x] Error Handling: Invalid API key shows clear error message
- [x] Performance: Full deployment completes in < 10 minutes
- [x] All acceptance gates from PRD pass

## Files Changed
- `fastlane/Fastfile` (new) - Deployment lanes
- `fastlane/Appfile` (new) - App configuration
- `fastlane/Matchfile` (new) - Certificate storage config
- `fastlane/.env.example` (new) - Environment variable template
- `fastlane/README.md` (new) - Setup documentation
- `.gitignore` (modified) - Exclude Fastlane sensitive files
- `README.md` (modified) - Add deployment section

## Related Documents
- PRD: `Psst/docs/prds/pr-017-prd.md`
- TODO: `Psst/docs/todos/pr-017-todo.md`

## Notes
- API key `.p8` file and `.env` are git-ignored for security
- Match password stored in [Team Password Manager Name]
- Requires Apple Developer Program membership ($99/year)
- First deployment may take longer (~12-15 min) due to initial Match setup
```

- [ ] Link PRD and TODO in PR description
- [ ] Request review from team

**Test Gate**: PR created with complete description, links to documentation

---

## 23. Final Checklist (Definition of Done)

Verify all items before marking PR ready:

- [ ] Fastlane installed and configured
- [ ] `Fastfile` with `beta`, `release`, `test` lanes implemented
- [ ] App Store Connect API key created and stored securely
- [ ] Match configured with certificate storage (GitHub repo)
- [ ] `.env.example` template created with all required variables
- [ ] `.gitignore` updated to exclude sensitive files
- [ ] `fastlane/README.md` documentation written with setup instructions
- [ ] Main `README.md` updated with deployment instructions
- [ ] Manual testing: `fastlane beta` successfully uploads to TestFlight
- [ ] Manual testing: New developer can run `fastlane match` and deploy
- [ ] All acceptance gates pass
- [ ] No sensitive files (API keys, `.env`) tracked in git
- [ ] Code follows project standards from `Psst/agents/shared-standards.md`

---

## Notes

- **Setup Time**: Initial setup ~30-45 minutes (API key creation, Match initialization)
- **Deployment Time**: ~5-10 minutes per beta deployment
- **Team Onboarding**: ~5 minutes for new developer to sync certificates
- **Match Password**: Store in team password manager (1Password, LastPass) immediately
- **API Key Security**: Never commit `.p8` files or `.env` to git
- **Certificate Renewal**: Match handles renewal automatically when certs expire (1 year)
- **Build Number**: Auto-incremented on each `fastlane beta` run, committed to git

**Blockers**:
- Requires active Apple Developer Program membership
- Requires permissions to create App Store Connect API keys
- Requires GitHub repo access for Match storage
