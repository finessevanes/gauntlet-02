# PRD: Fastlane Deployment Setup

**Feature**: Automated iOS Deployment Pipeline

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Caleb

**Target Release**: Infrastructure - Immediate

**Links**: [PR Brief: ai-briefs.md#pr-017](../ai-briefs.md), [TODO](../todos/pr-017-todo.md)

---

## 1. Summary

Implement automated iOS deployment pipeline using Fastlane with App Store Connect API authentication to enable single-command deployments to TestFlight and App Store, replacing manual Xcode Archive workflows.

---

## 2. Problem & Goals

**Problem**: Current deployment process requires manual Xcode archiving, signing, and uploading to App Store Connect, which is time-consuming, error-prone, and blocks CI/CD automation due to 2FA requirements.

**Why Now**: As AI features expand (PRs #001-016), rapid iteration and testing require streamlined deployment to TestFlight for beta testing.

**Goals**:
- [ ] G1 — Deploy to TestFlight with single command: `fastlane beta`
- [ ] G2 — Deploy to App Store with single command: `fastlane release`
- [ ] G3 — Automate code signing certificate management using Match
- [ ] G4 — Enable CI/CD integration without 2FA friction using App Store Connect API

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing GitHub Actions/CircleCI workflows (manual local deployment first)
- [ ] Not setting up automated screenshot generation (future enhancement)
- [ ] Not implementing beta tester management automation
- [ ] Not configuring App Store metadata updates via Fastlane (manual submission)

---

## 4. Success Metrics

**User-visible** (Developer Experience):
- Time to deploy: < 5 minutes from command to TestFlight availability
- Commands executed: 1 (`fastlane beta` or `fastlane release`)
- Setup time: < 30 minutes for new team member

**System**:
- Build success rate: >95% (no signing failures)
- Certificate sync: Match downloads certs in <10 seconds
- Upload time: Dependent on network (typically 2-5 min for 100MB IPA)

**Quality**:
- 0 manual Xcode interventions required
- No 2FA prompts during deployment
- Reproducible builds across all developer machines

---

## 5. Users & Stories

**As a developer**, I want to deploy to TestFlight with a single command so that I can quickly share builds with beta testers without navigating Xcode menus.

**As a team member**, I want automatic certificate management so that I don't have to manually install provisioning profiles or debug signing issues.

**As a CI/CD pipeline**, I want to authenticate using API keys (not Apple ID) so that automated deployments don't fail due to 2FA prompts.

**As a project maintainer**, I want consistent build configuration so that all team members produce identical signed builds.

---

## 6. Experience Specification (UX)

### Entry Points
1. **Local Terminal**: Developer runs `fastlane beta` from project root
2. **CI/CD Pipeline**: Automated workflow triggers `fastlane beta` on push to `develop`

### Visual Behavior (Terminal Output)
- Fastlane displays progress steps: "Building app...", "Signing with certificate...", "Uploading to TestFlight..."
- Success: "✅ Successfully uploaded to TestFlight. Build #42 processing."
- Failure: Clear error message with troubleshooting hints

### States
- **Building**: Xcode compiles app (3-5 min)
- **Signing**: Match retrieves certificates and signs IPA (10-30 sec)
- **Uploading**: IPA uploads to App Store Connect (2-5 min)
- **Processing**: Apple processes build (shown in App Store Connect, not Fastlane)

### Performance Targets
- Full deployment (beta lane): < 10 minutes total (build + sign + upload)
- Certificate retrieval (Match): < 10 seconds
- Command startup time: < 5 seconds

---

## 7. Functional Requirements (Must/Should)

**MUST**:
- Install Fastlane CLI via Homebrew or bundler
- Configure `Fastfile` with lanes: `beta`, `release`, `test`
- Set up App Store Connect API key authentication (JSON key file)
- Implement Match for certificate/provisioning profile management
- Store API keys securely outside git (`.gitignore` or environment variables)
- Support both development and production signing configurations
- Include error handling for common failures (expired certs, invalid API key, network timeout)

**SHOULD**:
- Generate screenshots automatically (`fastlane screenshots` lane)
- Run unit tests before deployment (`fastlane test` lane)
- Send Slack/email notifications on deployment success/failure

**Acceptance Gates**:
- [Gate] When developer runs `fastlane beta` → App uploads to TestFlight without manual intervention
- [Gate] When new team member runs `fastlane match` → Certificates install automatically without manual download
- [Gate] When CI/CD runs `fastlane beta` → No 2FA prompt, authentication succeeds via API key
- [Gate] When certificate expires → Match generates new cert automatically
- [Gate] Error case: Invalid API key shows clear error: "API key authentication failed. Check API_KEY_ID in .env"

---

## 8. Data Model

### App Store Connect API Key
```json
{
  "key_id": "ABC123XYZ",
  "issuer_id": "12345678-90ab-cdef-1234-567890abcdef",
  "key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----",
  "is_key_content_base64": false
}
```

**Storage**: JSON file at `fastlane/AuthKey_ABC123XYZ.p8` (git-ignored)

### Match Configuration
- **Storage**: Private GitHub repository `psst-certificates` (or encrypted Google Cloud Storage)
- **Certificates**: Development, Distribution (App Store)
- **Provisioning Profiles**: Development, App Store
- **Encryption**: Match password stored in `.env` file (git-ignored)

### Environment Variables (.env)
```bash
APP_STORE_CONNECT_API_KEY_ID="ABC123XYZ"
APP_STORE_CONNECT_ISSUER_ID="12345678-90ab-cdef-1234-567890abcdef"
APP_STORE_CONNECT_API_KEY_PATH="./fastlane/AuthKey_ABC123XYZ.p8"
MATCH_PASSWORD="super-secret-password-123"
MATCH_GIT_URL="git@github.com:your-org/psst-certificates.git"
```

---

## 9. API / Service Contracts

### Fastlane Lanes

```ruby
lane :beta do
  # 1. Ensure clean git state
  ensure_git_status_clean

  # 2. Increment build number
  increment_build_number(xcodeproj: "Psst.xcodeproj")

  # 3. Sync certificates/profiles
  match(type: "appstore", readonly: true)

  # 4. Build app
  build_app(
    scheme: "Psst",
    export_method: "app-store",
    destination: "platform=iOS Simulator,name=Vanes"
  )

  # 5. Upload to TestFlight
  upload_to_testflight(
    api_key_path: ENV["APP_STORE_CONNECT_API_KEY_PATH"],
    skip_waiting_for_build_processing: true
  )

  # 6. Commit build number bump
  commit_version_bump(
    message: "Bump build number [skip ci]",
    xcodeproj: "Psst.xcodeproj"
  )
end

lane :release do
  # Similar to beta but uses production signing and App Store upload
  match(type: "appstore", readonly: true)
  build_app(scheme: "Psst", export_method: "app-store")
  upload_to_app_store(api_key_path: ENV["APP_STORE_CONNECT_API_KEY_PATH"])
end

lane :test do
  run_tests(
    scheme: "Psst",
    devices: ["Vanes"],
    clean: true
  )
end

lane :screenshots do
  capture_screenshots(
    scheme: "PsstUITests",
    devices: ["iPhone 15 Pro", "iPad Pro (12.9-inch)"]
  )
end
```

### Match Commands

```bash
# Initial setup (first time only)
fastlane match init

# Generate new certificates
fastlane match appstore

# Sync existing certificates (readonly)
fastlane match appstore --readonly

# Renew certificates (when expired)
fastlane match nuke distribution
fastlane match appstore
```

**Error Handling**:
- **Expired certificate**: Match auto-generates new cert if `readonly: false`
- **Invalid API key**: Clear error message with troubleshooting steps
- **Build failure**: Shows Xcode error log with line numbers
- **Network timeout**: Retry upload with exponential backoff (3 retries)

---

## 10. UI Components to Create/Modify

### Files to Create
- `fastlane/Fastfile` — Main Fastlane configuration with lanes
- `fastlane/Appfile` — App identifier and Apple ID configuration
- `fastlane/Matchfile` — Match certificate storage configuration
- `fastlane/.env` — Environment variables (git-ignored, use `.env.example` template)
- `fastlane/.env.example` — Template showing required environment variables
- `fastlane/README.md` — Setup instructions and lane documentation

### Files to Modify
- `.gitignore` — Add `fastlane/report.xml`, `fastlane/AuthKey_*.p8`, `fastlane/.env`
- `README.md` — Add deployment instructions section

### Files to Git-Ignore
```
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots
fastlane/.env
fastlane/AuthKey_*.p8
*.ipa
*.dSYM.zip
```

---

## 11. Integration Points

- **App Store Connect API**: Authentication, app upload, TestFlight management
- **Xcode**: Build automation, scheme selection, signing configuration
- **Match**: Certificate storage (GitHub repo or Google Cloud Storage)
- **Git**: Version control for build number commits
- **Bundler** (optional): Ruby dependency management for Fastlane gems

---

## 12. Testing Plan & Acceptance Gates

### Happy Path
- [ ] Developer runs `fastlane beta` from terminal
- [ ] **Gate:** Fastlane builds app → Signs with App Store cert → Uploads to TestFlight → Success message shown
- [ ] **Pass Criteria:** Build appears in App Store Connect TestFlight within 5 minutes, no errors in terminal

**Steps**:
1. Open terminal in project root
2. Run `fastlane beta`
3. Wait for completion (5-10 min)
4. Verify build in App Store Connect → TestFlight → Builds
5. Confirm build number incremented in Xcode

---

### Edge Cases

- [ ] **Edge Case 1: First-time setup (no certificates)**
  - **Test:** New developer runs `fastlane match appstore` on fresh machine
  - **Expected:** Match downloads certificates from storage repo, installs in Keychain, provisioning profiles installed
  - **Pass:** Certificates visible in Keychain Access, subsequent `fastlane beta` succeeds

- [ ] **Edge Case 2: Expired certificate**
  - **Test:** Certificate expires → Run `fastlane match appstore` (without `--readonly`)
  - **Expected:** Match detects expiration, generates new certificate, uploads to storage repo
  - **Pass:** New certificate created, TestFlight upload succeeds

- [ ] **Edge Case 3: Build number conflict**
  - **Test:** TestFlight already has build #42 → Run `fastlane beta` with same build number
  - **Expected:** Upload fails with clear error: "Build #42 already exists. Increment build number."
  - **Pass:** Error message shown, developer can re-run after incrementing

---

### Error Handling

- [ ] **Offline Mode**
  - **Test:** Disconnect internet → Run `fastlane beta`
  - **Expected:** Build succeeds locally, upload fails with "No internet connection. IPA saved at [path]. Retry upload when online."
  - **Pass:** IPA file saved, can manually upload or retry Fastlane

- [ ] **Invalid API Key**
  - **Test:** Delete `.env` file → Run `fastlane beta`
  - **Expected:** Error message: "APP_STORE_CONNECT_API_KEY_PATH not found. See fastlane/README.md for setup instructions."
  - **Pass:** Clear error message with troubleshooting link

- [ ] **Xcode Build Failure**
  - **Test:** Introduce Swift compilation error → Run `fastlane beta`
  - **Expected:** Build fails with Xcode error log showing file/line number
  - **Pass:** Developer can identify and fix error from terminal output

- [ ] **Match Password Incorrect**
  - **Test:** Change `MATCH_PASSWORD` in `.env` to wrong value → Run `fastlane match appstore --readonly`
  - **Expected:** Error: "Failed to decrypt certificates. Verify MATCH_PASSWORD is correct."
  - **Pass:** Clear error message, developer knows to check password

---

### Performance Check

- [ ] **Full deployment (beta) completes in < 10 minutes**
  - Build: ~5 min
  - Sign: ~30 sec
  - Upload: ~3 min (100MB IPA)
  - **Pass:** Total time < 10 min on average internet connection

- [ ] **Match certificate sync completes in < 10 seconds**
  - **Pass:** Certificates download and install quickly

---

## 13. Definition of Done

- [ ] Fastlane installed and configured
- [ ] `Fastfile` with `beta`, `release`, `test` lanes implemented
- [ ] App Store Connect API key created and stored securely
- [ ] Match configured with certificate storage (GitHub repo or GCS)
- [ ] `.env.example` template created with all required variables
- [ ] `.gitignore` updated to exclude sensitive files
- [ ] `fastlane/README.md` documentation written with setup instructions
- [ ] Manual testing: `fastlane beta` successfully uploads to TestFlight
- [ ] Manual testing: New developer can run `fastlane match` and deploy
- [ ] All acceptance gates pass
- [ ] Main README updated with deployment instructions

---

## 14. Risks & Mitigations

**Risk**: API key leaked in git history
- **Mitigation**: Store in `.env` (git-ignored), add pre-commit hook to block commits with API keys, use `.env.example` template

**Risk**: Match password forgotten
- **Mitigation**: Store password in team password manager (1Password, LastPass), document in onboarding guide

**Risk**: Certificate storage repo access issues
- **Mitigation**: Use GitHub repo with team access, or Google Cloud Storage with IAM permissions, document access setup in README

**Risk**: Fastlane version incompatibility
- **Mitigation**: Use Bundler to lock Fastlane version (`Gemfile`), document required version in README

**Risk**: Apple Developer Program membership expires
- **Mitigation**: Set calendar reminders for renewal, document renewal process

---

## 15. Rollout & Telemetry

**Feature Flag**: No (infrastructure change, not user-facing)

**Metrics**:
- Deployment frequency: Track builds uploaded per week
- Build success rate: Monitor `fastlane beta` failures
- Setup time: Measure time for new developer to successfully deploy

**Manual Validation**:
1. Run `fastlane beta` and verify build in TestFlight
2. Have team member clone repo, run `fastlane match`, verify certificates installed
3. Simulate API key expiration, verify error handling

---

## 16. Open Questions

- **Q1**: Should we use GitHub repo or Google Cloud Storage for Match certificate storage?
  - **Decision**: GitHub repo (simpler for small team, free, familiar tool)

- **Q2**: Should we auto-increment build number or require manual increment?
  - **Decision**: Auto-increment in `beta` lane, manual in `release` lane

- **Q3**: Should we send Slack notifications on deployment?
  - **Decision**: Out of scope for initial setup, can add later

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] GitHub Actions CI/CD workflow automation
- [ ] Automated screenshot generation for App Store
- [ ] Beta tester management via Fastlane
- [ ] App Store metadata updates (description, keywords) via Fastlane
- [ ] Slack/Discord deployment notifications
- [ ] Automated changelog generation from git commits

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - Developer runs `fastlane beta`, app uploads to TestFlight without manual Xcode intervention

2. **Primary user and critical action?**
   - Developer deploying builds to TestFlight for beta testing

3. **Must-have vs nice-to-have?**
   - Must: `beta` and `release` lanes, Match setup, API key auth
   - Nice: Screenshot generation, test lane, notifications

4. **Real-time requirements?**
   - None (infrastructure tooling)

5. **Performance constraints?**
   - Deployment should complete in <10 minutes (acceptable for manual workflow)

6. **Error/edge cases to handle?**
   - Invalid API key, expired certificates, network failures, build conflicts

7. **Data model changes?**
   - None (iOS app unchanged, only deployment tooling)

8. **Service APIs required?**
   - App Store Connect API for uploads, Match for certificate storage

9. **UI entry points and states?**
   - Terminal only (no iOS UI changes)

10. **Security/permissions implications?**
    - API keys must be secured (git-ignored), Match password must be team-shared securely

11. **Dependencies or blocking integrations?**
    - Requires Apple Developer Program membership ($99/year)
    - Requires App Store Connect API key creation (manual setup)

12. **Rollout strategy and metrics?**
    - One-time setup, track deployment frequency and success rate

13. **What is explicitly out of scope?**
    - CI/CD automation, screenshot generation, metadata updates, notifications

---

## Authoring Notes

- Focus on manual local deployment first (CI/CD is future enhancement)
- Prioritize clear error messages and documentation
- Match simplifies certificate management across team
- App Store Connect API key avoids 2FA friction
- Use `.env.example` pattern to document required variables without leaking secrets
