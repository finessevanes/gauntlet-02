# Fastlane Quick Start Cheat Sheet

## 🚀 Most Common Commands

```bash
# Deploy to TestFlight (beta testers)
fastlane beta

# Deploy to App Store (production)
fastlane release

# Run tests
fastlane test
```

---

## ⚡ First Time on a New Machine

```bash
# 1. Copy .env file to fastlane/ folder
#    (Get it from secure location or create from .env.example)

# 2. Download certificates
fastlane match_dev
fastlane match_appstore

# 3. You're ready!
fastlane beta
```

---

## 📝 What Each File Does

| File | Purpose | Commit to Git? |
|------|---------|----------------|
| `.env` | Your secrets (API keys, passwords) | ❌ NO - Keep secret! |
| `.env.example` | Template for .env | ✅ Yes |
| `Fastfile` | Automation scripts | ✅ Yes |
| `Matchfile` | Certificate config | ✅ Yes |
| `README.md` | Full documentation | ✅ Yes |

---

## 🔑 Critical Environment Variables

Must be in `fastlane/.env`:

```bash
APP_STORE_CONNECT_API_KEY_ID="NAQ9D689Q4"
APP_STORE_CONNECT_ISSUER_ID="56106e83-02e2-4c2c-8433-040b47d2c425"
APP_STORE_CONNECT_API_KEY_FILEPATH="./fastlane/AuthKey_NAQ9D689Q4.p8"
MATCH_GIT_URL="https://github.com/finessevanes/psst-certificates.git"
MATCH_PASSWORD="your-match-password"
```

**IMPORTANT:** Use `FILEPATH` not `PATH` (common mistake!)

---

## 🔧 Common Fixes

### "Agreement missing or expired"
→ Go to https://developer.apple.com/account with **vanessa.mercado24@gmail.com**
→ Accept pending agreements
→ Wait 5-10 minutes

### "Conflict between api_key_path and api_key"
→ Check `.env` uses `APP_STORE_CONNECT_API_KEY_FILEPATH` (not `_PATH`)
→ Restart terminal

### "Git not clean"
→ Commit your changes first: `git add . && git commit -m "message"`

---

## 📱 After Deployment

### TestFlight (beta)
- Wait 5-10 minutes for processing
- Invite testers at https://appstoreconnect.apple.com
- Testers get notification in TestFlight app

### App Store (release)
- Upload completes but NOT submitted
- Go to https://appstoreconnect.apple.com
- Fill in metadata/screenshots
- Manually submit for review

---

## 🔒 Security Reminders

1. **NEVER commit `.env`** - Has all your secrets
2. **Certificate repo must be PRIVATE** - Contains signing certs
3. **Save Match password securely** - Can't recover if lost
4. **Keep `.p8` file safe** - Can't regenerate

---

## 📞 Quick Links

- **App Store Connect:** https://appstoreconnect.apple.com
- **Apple Developer:** https://developer.apple.com/account
- **Full README:** See `fastlane/README.md`

---

**Your Apple ID:** vanessa.mercado24@gmail.com
**App ID:** gauntlet.Psst
**Certificate Repo:** github.com/finessevanes/psst-certificates
