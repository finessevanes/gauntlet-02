# Fastlane Setup & Documentation

Automated iOS deployment pipeline for Psst app using Fastlane with App Store Connect API authentication.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Available Lanes](#available-lanes)
- [New Team Member Setup](#new-team-member-setup)
- [Troubleshooting](#troubleshooting)
- [Security Notes](#security-notes)

---

## Overview

Fastlane automates the entire iOS deployment process:

- **Single Command Deployments**: `fastlane beta` or `fastlane release`
- **Automated Code Signing**: Match manages certificates and provisioning profiles
- **No 2FA Friction**: App Store Connect API key authentication
- **Consistent Builds**: Same configuration across all developer machines

---

## Prerequisites

Before setting up Fastlane, ensure you have:

- [x] **Xcode** installed (latest version recommended)
- [x] **Homebrew** package manager ([install here](https://brew.sh))
- [x] **Apple Developer Program** membership ($99/year)
- [x] **App Store Connect** access with sufficient permissions
- [x] **Git** access to certificate storage repository

---

## Initial Setup

### 1. Install Fastlane

```bash
# Install via Homebrew (recommended)
brew install fastlane

# Verify installation
fastlane --version
```

### 2. Create App Store Connect API Key

This enables API-based authentication without 2FA prompts.

**Steps:**
1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to: **Users and Access** → **Keys** → **App Store Connect API**
3. Click **"+"** to create a new API key
4. **Name**: "Fastlane CI" (or any descriptive name)
5. **Access**: Select **"Developer"** role
6. Click **Generate**
7. **Download** the `.p8` private key file (⚠️ only available once!)
8. Note the **Key ID** and **Issuer ID** displayed on the page

**Important**: Store the `.p8` file securely - it cannot be re-downloaded!

### 3. Configure Environment Variables

```bash
# Navigate to project root
cd /path/to/Psst

# Copy template to create .env file
cp fastlane/.env.example fastlane/.env

# Edit .env with your actual values
nano fastlane/.env
```

**Required values** (update in `.env`):

```bash
# Replace with your Key ID from App Store Connect
APP_STORE_CONNECT_API_KEY_ID="ABC123XYZ"

# Replace with your Issuer ID from App Store Connect
APP_STORE_CONNECT_ISSUER_ID="12345678-90ab-cdef-1234-567890abcdef"

# Update path with your Key ID
APP_STORE_CONNECT_API_KEY_PATH="./fastlane/AuthKey_ABC123XYZ.p8"

# Generate a strong random password (save in team password manager!)
MATCH_PASSWORD="your-super-secret-password-123"

# Replace with your certificate storage repo URL
MATCH_GIT_URL="git@github.com:your-org/psst-certificates.git"
```

### 4. Move API Key File

```bash
# Move downloaded .p8 file to fastlane directory
mv ~/Downloads/AuthKey_ABC123XYZ.p8 fastlane/

# Verify it's git-ignored (should NOT appear in git status)
git status
```

### 5. Create Certificate Storage Repository

Match stores code signing certificates in a private Git repository.

```bash
# Create a NEW private GitHub repository named "psst-certificates"
# (Do this via GitHub web interface)

# Or use GitHub CLI:
gh repo create psst-certificates --private

# Update MATCH_GIT_URL in .env with the repository URL
```

### 6. Initialize Match (First Time Only)

```bash
# Generate and upload App Store certificates
fastlane match_appstore

# Generate and upload Development certificates (optional)
fastlane match_dev
```

**What this does:**
- Generates code signing certificates
- Creates provisioning profiles
- Encrypts them with `MATCH_PASSWORD`
- Uploads to your certificate storage repository
- Installs certificates in your Mac's Keychain

⚠️ **Important**: Save `MATCH_PASSWORD` in your team password manager (1Password, LastPass, etc.) immediately!

---

## Available Lanes

### `fastlane beta`

Deploy to **TestFlight** for beta testing.

```bash
fastlane beta
```

**What it does:**
1. Ensures clean git state (fails if uncommitted changes)
2. Auto-increments build number
3. Syncs certificates from Match
4. Builds the app (.ipa file)
5. Uploads to TestFlight
6. Commits build number bump to git

**Time:** ~5-10 minutes (build + upload)

**Result:** Build available in TestFlight after Apple processing (~5-10 min)

---

### `fastlane release`

Deploy to **App Store** (manual submission required).

```bash
fastlane release
```

**What it does:**
1. Ensures clean git state
2. Syncs App Store certificates
3. Builds the app
4. Uploads to App Store Connect
5. Does **NOT** submit for review (do this manually in App Store Connect)

**Time:** ~5-10 minutes

**Next step:** Complete submission in [App Store Connect](https://appstoreconnect.apple.com)

---

### `fastlane test`

Run **unit tests and UI tests**.

```bash
fastlane test
```

**What it does:**
- Runs all tests on "Vanes" simulator
- Generates code coverage report
- Outputs results to `fastlane/test_output/`

**Time:** ~2-5 minutes (depends on test suite size)

---

### `fastlane screenshots`

Generate **App Store screenshots** automatically.

```bash
fastlane screenshots
```

**What it does:**
- Runs UI tests to capture screenshots
- Generates screenshots for iPhone 15 Pro, iPhone 15 Pro Max, iPad Pro
- Saves to `fastlane/screenshots/`

**Requirements:** UI tests must be configured to capture screenshots

---

### `fastlane match_appstore`

Sync **App Store certificates** from Match storage.

```bash
fastlane match_appstore
```

**When to use:**
- First-time setup on a new machine
- Certificate expired and needs regeneration
- New team member joining

---

### `fastlane match_dev`

Sync **development certificates** from Match storage.

```bash
fastlane match_dev
```

**When to use:**
- Setting up development environment
- Running app on physical device

---

## New Team Member Setup

When a new developer joins the team:

### 1. Install Prerequisites

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Fastlane
brew install fastlane

# Verify installation
fastlane --version
```

### 2. Get Credentials

From team password manager, retrieve:
- `MATCH_PASSWORD` (certificate encryption password)
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- Access to `.p8` API key file

### 3. Configure Environment

```bash
# Clone project
git clone git@github.com:your-org/Psst.git
cd Psst

# Create .env from template
cp fastlane/.env.example fastlane/.env

# Edit with actual values
nano fastlane/.env

# Add .p8 file to fastlane/ directory
# (Get from team password manager or App Store Connect)
```

### 4. Sync Certificates

```bash
# Sync App Store certificates
fastlane match_appstore

# Sync Development certificates (optional)
fastlane match_dev
```

### 5. Verify Setup

```bash
# Try deploying to TestFlight
fastlane beta
```

**Success!** You should see build uploaded to TestFlight.

**Time to productive:** ~15-30 minutes

---

## Troubleshooting

### Error: "APP_STORE_CONNECT_API_KEY_PATH not found"

**Cause:** `.env` file missing or API key path incorrect

**Fix:**
```bash
# Verify .env exists
ls -la fastlane/.env

# Verify .p8 file exists
ls -la fastlane/AuthKey_*.p8

# Check path in .env matches actual filename
cat fastlane/.env | grep APP_STORE_CONNECT_API_KEY_PATH
```

---

### Error: "Failed to decrypt certificates"

**Cause:** Incorrect `MATCH_PASSWORD`

**Fix:**
```bash
# Verify password in team password manager
# Update .env with correct password
nano fastlane/.env

# Retry Match sync
fastlane match_appstore --readonly
```

---

### Error: "Git status not clean"

**Cause:** Uncommitted changes in repository

**Fix:**
```bash
# Commit or stash changes first
git status
git add .
git commit -m "commit message"

# Then retry deployment
fastlane beta
```

---

### Error: "Certificate has expired"

**Cause:** Code signing certificate expired (certificates last 1 year)

**Fix:**
```bash
# Delete expired certificate from Match
fastlane match nuke distribution

# Generate new certificate
fastlane match_appstore

# Retry deployment
fastlane beta
```

---

### Error: "Build number already exists"

**Cause:** TestFlight already has a build with this number

**Fix:**
```bash
# Manually increment build number in Xcode
# Or run beta lane again (auto-increments)
fastlane beta
```

---

### Error: "Network timeout during upload"

**Cause:** Slow internet connection or large IPA file

**Fix:**
- Retry upload (Fastlane will resume)
- Check internet connection
- Upload during off-peak hours
- Consider compressing assets

---

### Error: "Provisioning profile doesn't match"

**Cause:** Mismatch between app identifier and profile

**Fix:**
```bash
# Re-sync provisioning profiles
fastlane match_appstore --force_for_new_devices

# Or regenerate completely
fastlane match nuke distribution
fastlane match_appstore
```

---

## Security Notes

### Files to NEVER commit to git:

- ❌ `fastlane/.env` (contains secrets)
- ❌ `fastlane/AuthKey_*.p8` (API private key)
- ❌ `*.ipa` (build artifacts)
- ❌ `*.mobileprovision` (provisioning profiles)

These are already in `.gitignore` ✅

### Best Practices:

1. **Store secrets in team password manager**
   - `MATCH_PASSWORD`
   - `.p8` API key file
   - App Store Connect credentials

2. **Rotate API keys periodically**
   - Every 6-12 months
   - When team members leave
   - If key is suspected to be compromised

3. **Use separate API keys for CI/CD**
   - Different key for local development vs automated CI

4. **Limit API key permissions**
   - Use "Developer" role (not "Admin")
   - Principle of least privilege

5. **Certificate storage repo access**
   - Keep `psst-certificates` repo private
   - Only grant access to trusted team members
   - Use SSH keys (not HTTPS passwords)

---

## Additional Resources

- **Fastlane Docs**: https://docs.fastlane.tools
- **Match Docs**: https://docs.fastlane.tools/actions/match
- **App Store Connect API**: https://developer.apple.com/app-store-connect/api
- **Troubleshooting**: https://docs.fastlane.tools/troubleshooting

---

## Quick Reference

```bash
# Deploy to TestFlight
fastlane beta

# Deploy to App Store (manual submission)
fastlane release

# Run tests
fastlane test

# Generate screenshots
fastlane screenshots

# Sync certificates (new machine)
fastlane match_appstore --readonly

# Regenerate expired certificates
fastlane match nuke distribution
fastlane match_appstore

# View all available lanes
fastlane lanes
```

---

**Questions?** See main project [README.md](../README.md) or contact the team.
