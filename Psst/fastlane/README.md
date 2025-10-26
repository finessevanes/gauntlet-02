# Fastlane Setup & Usage Guide for Psst

Complete guide for iOS deployment automation using Fastlane.

---

## Table of Contents
1. [First-Time Setup](#first-time-setup)
2. [Daily Usage](#daily-usage)
3. [Available Commands](#available-commands)
4. [Troubleshooting](#troubleshooting)
5. [File Reference](#file-reference)

---

## First-Time Setup

### Prerequisites
- Xcode installed
- Apple Developer account (vanessa.mercado24@gmail.com)
- GitHub account with access to certificate repo

### Step 1: Install Fastlane
```bash
# Install fastlane (if not already installed)
brew install fastlane

# Or using RubyGems
sudo gem install fastlane
```

### Step 2: Configure Environment Variables

1. **Copy the example .env file:**
   ```bash
   cd /path/to/Psst
   cp fastlane/.env.example fastlane/.env
   ```

2. **Edit `fastlane/.env` with your values:**
   ```bash
   # App Store Connect API Authentication
   APP_STORE_CONNECT_API_KEY_ID="YOUR_KEY_ID"
   APP_STORE_CONNECT_ISSUER_ID="YOUR_ISSUER_ID"
   APP_STORE_CONNECT_API_KEY_FILEPATH="./fastlane/AuthKey_YOUR_KEY_ID.p8"

   # Match Certificate Management
   MATCH_GIT_URL="https://github.com/YOUR_USERNAME/psst-certificates.git"
   MATCH_PASSWORD="YOUR_STRONG_PASSWORD"
   ```

3. **Get App Store Connect API Key:**
   - Go to https://appstoreconnect.apple.com/access/api
   - Navigate to: **Users and Access → Keys → App Store Connect API**
   - Click **"+"** to create a new key
   - Name it "Fastlane Deployment"
   - Select **Admin** access
   - Download the `.p8` file
   - Copy the **Key ID** and **Issuer ID**
   - Place the `.p8` file in `fastlane/` folder
   - Update `.env` with these values

### Step 3: Create Certificate Repository

1. **Create a PRIVATE GitHub repo:**
   ```bash
   # On GitHub: Create new repo named "psst-certificates"
   # Make it PRIVATE (important for security!)
   ```

2. **Update `.env` with repo URL:**
   ```bash
   MATCH_GIT_URL="https://github.com/YOUR_USERNAME/psst-certificates.git"
   ```

3. **Choose a strong Match password:**
   ```bash
   # This encrypts your certificates in the repo
   MATCH_PASSWORD="YourStrongPassword123!"
   ```

### Step 4: Initialize Certificates

**Run these commands in order:**

```bash
# Navigate to Psst directory
cd /path/to/Psst

# Generate development certificates
fastlane match_dev

# Generate App Store certificates
fastlane match_appstore
```

**What this does:**
- Creates signing certificates in your Apple Developer account
- Generates provisioning profiles
- Stores them encrypted in your GitHub repo
- Installs them on your Mac

**IMPORTANT:** Save your `MATCH_PASSWORD` somewhere safe! You'll need it on other machines or CI/CD.

---

## Daily Usage

### Deploy to TestFlight (Beta Testing)

```bash
cd /path/to/Psst
fastlane beta
```

**What this does:**
1. Checks git is clean (commit your changes first!)
2. Increments build number automatically
3. Syncs certificates from Match repo
4. Builds the app
5. Uploads to TestFlight
6. Commits the build number bump

**After upload:**
- Build processes in ~5-10 minutes
- Available in TestFlight app
- Invite testers in App Store Connect

### Deploy to App Store (Production)

```bash
cd /path/to/Psst
fastlane release
```

**What this does:**
1. Syncs certificates
2. Builds the app
3. Uploads to App Store Connect
4. **Does NOT submit for review** (you do this manually)

**To complete submission:**
1. Go to https://appstoreconnect.apple.com
2. Go to your app → App Store tab
3. Fill in metadata, screenshots, description
4. Submit for review

### Run Tests

```bash
cd /path/to/Psst
fastlane test
```

Runs unit and UI tests on the "Vanes" simulator.

---

## Available Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `fastlane beta` | Deploy to TestFlight | Share with beta testers |
| `fastlane release` | Upload to App Store | Production release |
| `fastlane test` | Run all tests | Before deploying |
| `fastlane screenshots` | Generate App Store screenshots | Before App Store submission |
| `fastlane match_dev` | Sync dev certificates | First time or new machine |
| `fastlane match_appstore` | Sync production certificates | First time or new machine |

---

## Troubleshooting

### "A required agreement is missing or has expired"

**Solution:**
1. Go to https://developer.apple.com/account
2. Sign in with **vanessa.mercado24@gmail.com**
3. Check for pending agreements banner at top
4. Accept any pending agreements
5. Wait 5-10 minutes for Apple's systems to update
6. Try command again

### "Unresolved conflict between options: 'api_key_path' and 'api_key'"

**Solution:**
1. Make sure `.env` uses `APP_STORE_CONNECT_API_KEY_FILEPATH` (not `_PATH`)
2. Check Fastfile uses `key_filepath` parameter
3. Restart terminal to reload environment variables

### "Could not find the newly generated certificate"

**Solution:**
1. Delete certificates from Apple Developer Portal manually
2. Run `fastlane match_appstore --force` to regenerate
3. Enter Match password when prompted

### "Wrong password for certificates repo"

**Solution:**
1. Check `MATCH_PASSWORD` in `.env` file
2. Make sure no extra quotes or spaces
3. If forgotten, you'll need to revoke and regenerate all certificates

### "No spaces in srcroot"

**Solution:**
- Your project path has spaces
- Move project to path without spaces (e.g., `/Users/username/Projects/Psst`)

### Git Not Clean Error

**Solution:**
```bash
# Commit your changes first
git add .
git commit -m "your commit message"

# Then run fastlane again
fastlane beta
```

---

## File Reference

### `.env` - Environment Variables (KEEP SECRET!)
Contains:
- App Store Connect API credentials
- Certificate repo URL
- Match password

**IMPORTANT:** Never commit this file! It's in `.gitignore`.

### `.env.example` - Template
Template for setting up `.env` on new machines.

### `Fastfile` - Automation Scripts
Defines all lanes (commands):
- `beta` - TestFlight deployment
- `release` - App Store deployment
- `test` - Run tests
- `match_dev` / `match_appstore` - Certificate management

### `Matchfile` - Certificate Configuration
Configuration for Match:
- Git repo URL
- App identifier (gauntlet.Psst)
- Apple ID (vanessa.mercado24@gmail.com)

### `Appfile` - App Metadata
Basic app configuration:
- App identifier
- Apple ID
- Team ID

---

## Important Notes

### Security Best Practices
1. **Never commit `.env`** - Contains secrets
2. **Keep Match password safe** - Can't recover if lost
3. **Certificate repo must be PRIVATE** - Contains signing certificates
4. **Limit API key access** - Only give to trusted team members

### Using on Multiple Machines

**On a new Mac:**
1. Clone the Psst repo
2. Copy `.env` file from secure location (or create new from `.env.example`)
3. Run `fastlane match_dev` to download certificates
4. Run `fastlane match_appstore` to download production certificates
5. Ready to deploy!

### CI/CD (GitHub Actions, etc.)

Store these as secrets:
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `MATCH_PASSWORD`
- Upload `.p8` file as secret file

---

## Quick Reference

### First Time Setup
```bash
# 1. Install fastlane
brew install fastlane

# 2. Setup environment
cp fastlane/.env.example fastlane/.env
# Edit .env with your credentials

# 3. Initialize certificates
fastlane match_dev
fastlane match_appstore
```

### Daily Workflow
```bash
# Test before deploying
fastlane test

# Deploy to TestFlight
git add . && git commit -m "Ready for beta"
fastlane beta

# Deploy to App Store
fastlane release
```

---

## Support

- **Fastlane Docs:** https://docs.fastlane.tools
- **Match Guide:** https://docs.fastlane.tools/actions/match/
- **TestFlight Guide:** https://docs.fastlane.tools/actions/upload_to_testflight/
- **App Store Connect:** https://appstoreconnect.apple.com

---

**Last Updated:** 2025-01-25
**Project:** Psst iOS App
**Developer:** vanessa.mercado24@gmail.com
