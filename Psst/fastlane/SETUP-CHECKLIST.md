# Fastlane Setup Checklist

Use this checklist when setting up fastlane on a new machine or fresh project.

---

## ✅ Prerequisites

- [ ] Xcode installed
- [ ] Homebrew installed
- [ ] Apple Developer account credentials (vanessa.mercado24@gmail.com)
- [ ] GitHub account access

---

## ✅ One-Time Apple Setup (if not done)

- [ ] Create App Store Connect API Key:
  - [ ] Go to https://appstoreconnect.apple.com/access/api
  - [ ] Sign in with vanessa.mercado24@gmail.com
  - [ ] Navigate to: Users and Access → Keys → App Store Connect API
  - [ ] Click "+" to create new key
  - [ ] Name: "Fastlane Deployment"
  - [ ] Access: Admin
  - [ ] Download `.p8` file (SAVE THIS - can't download again!)
  - [ ] Copy Key ID (e.g., "NAQ9D689Q4")
  - [ ] Copy Issuer ID (e.g., "56106e83-02e2-...")

- [ ] Create Private GitHub Repo for Certificates:
  - [ ] Go to GitHub
  - [ ] Create new repository: "psst-certificates"
  - [ ] Make it **PRIVATE** (critical!)
  - [ ] Don't initialize with README
  - [ ] Copy repo URL

---

## ✅ Fastlane Installation

```bash
# Install fastlane
brew install fastlane

# Verify installation
fastlane --version
```

- [ ] Fastlane installed successfully

---

## ✅ Project Configuration

```bash
# Navigate to project
cd /path/to/Psst

# Copy example env file
cp fastlane/.env.example fastlane/.env
```

- [ ] `.env` file created in `fastlane/` folder

---

## ✅ Configure .env File

Edit `fastlane/.env` with these values:

- [ ] `APP_STORE_CONNECT_API_KEY_ID` = (from App Store Connect)
- [ ] `APP_STORE_CONNECT_ISSUER_ID` = (from App Store Connect)
- [ ] `APP_STORE_CONNECT_API_KEY_FILEPATH` = `"./fastlane/AuthKey_YOUR_KEY_ID.p8"`
- [ ] `MATCH_GIT_URL` = (your GitHub certificate repo URL)
- [ ] `MATCH_PASSWORD` = (choose a strong password - SAVE THIS!)

**Example:**
```bash
APP_STORE_CONNECT_API_KEY_ID="NAQ9D689Q4"
APP_STORE_CONNECT_ISSUER_ID="56106e83-02e2-4c2c-8433-040b47d2c425"
APP_STORE_CONNECT_API_KEY_FILEPATH="./fastlane/AuthKey_NAQ9D689Q4.p8"
MATCH_GIT_URL="https://github.com/finessevanes/psst-certificates.git"
MATCH_PASSWORD="YourStrongPasswordHere"
```

- [ ] All environment variables configured
- [ ] Match password saved somewhere safe

---

## ✅ Add API Key File

- [ ] Copy the `.p8` file you downloaded earlier
- [ ] Place it in `fastlane/` folder
- [ ] Rename to match your Key ID: `AuthKey_YOUR_KEY_ID.p8`
- [ ] Verify path in `.env` matches the filename

**Example:**
```
Psst/
└── fastlane/
    ├── .env
    ├── AuthKey_NAQ9D689Q4.p8  ← This file
    ├── Fastfile
    └── Matchfile
```

- [ ] `.p8` file in correct location

---

## ✅ Initialize Certificates

```bash
# From Psst directory
cd /path/to/Psst

# Generate development certificates
fastlane match_dev

# When prompted, enter your Match password
# GitHub may prompt for authentication - use personal access token

# Generate App Store certificates
fastlane match_appstore
```

- [ ] Development certificates created successfully
- [ ] App Store certificates created successfully
- [ ] Certificates stored in GitHub repo (check: github.com/YOUR_USERNAME/psst-certificates)

---

## ✅ Verify Setup

```bash
# Run tests to verify everything works
fastlane test
```

- [ ] Tests run successfully
- [ ] No certificate errors
- [ ] Ready to deploy!

---

## ✅ Test Deployment (Optional)

```bash
# Make sure git is clean
git status

# If you have uncommitted changes:
git add .
git commit -m "Setup fastlane"

# Try a beta deployment
fastlane beta
```

- [ ] Beta deployment successful (or skip this for now)

---

## 🎉 Setup Complete!

You're now ready to use fastlane for iOS deployments!

### Quick Commands Reference:
```bash
fastlane beta          # Deploy to TestFlight
fastlane release       # Upload to App Store
fastlane test          # Run tests
```

### Important Reminders:
- 🔒 **Keep `.env` secret** - Never commit to git
- 🔑 **Save Match password** - You'll need it on other machines
- 🔐 **Certificate repo = PRIVATE** - Never make it public
- 💾 **Save `.p8` file** - Can't download from Apple again

---

## 📚 Additional Resources

- Full documentation: `fastlane/README.md`
- Quick reference: `fastlane/QUICK-START.md`
- Fastlane docs: https://docs.fastlane.tools

---

## 🆘 Common Issues During Setup

### "Agreement missing or expired"
→ Go to https://developer.apple.com/account
→ Accept pending agreements
→ Wait 5-10 minutes

### "Could not find API key file"
→ Check `.p8` file is in `fastlane/` folder
→ Check filename matches `APP_STORE_CONNECT_API_KEY_FILEPATH` in `.env`

### "Wrong password for certificates repo"
→ Check `MATCH_PASSWORD` in `.env`
→ No quotes or extra spaces

### GitHub authentication fails
→ Use personal access token instead of password
→ Create at: https://github.com/settings/tokens

---

**Last Updated:** 2025-01-25
