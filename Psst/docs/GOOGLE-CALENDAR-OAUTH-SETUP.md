# Google Calendar OAuth 2.0 Setup Guide

**Created for PR #010C: Google Calendar Integration (One-Way Sync)**

This guide walks through setting up Google Calendar OAuth 2.0 credentials for the Psst app.

---

## Quick Reference

**Before you start, you'll need:**
- Google Cloud Console access
- iOS app Bundle ID (default: `com.psst.Psst`)
- 15-20 minutes

**Setup flow:**
1. Create Google Cloud project + enable Calendar API
2. Configure OAuth consent screen
3. Create iOS OAuth 2.0 Client ID
4. Copy `Secrets.plist.example` → `Secrets.plist` and fill in credentials
5. Update `Info.plist` URL scheme (if not already set)
6. Add redirect URI to Google Cloud Console
7. Test OAuth flow in app

**Key files you'll modify:**
- `Psst/Psst/Secrets.plist` (create from example) ← **Your OAuth credentials go here**
- `Psst/Psst/Info.plist` (verify URL scheme matches)

**Critical format requirements:**
- Client ID: `505865284795-abc123...apps.googleusercontent.com` (from Google)
- Redirect URI: `com.googleusercontent.apps.505865284795-abc123:/oauth2callback`
- URL Scheme: `com.googleusercontent.apps.505865284795-abc123` (no `:/oauth2callback`)

All three must use the **same numeric ID** from your Client ID!

---

## Overview

Psst syncs calendar events to Google Calendar using OAuth 2.0 authentication. Users connect their Google account once in Settings, and all future events sync automatically.

**Sync Direction:** Psst → Google Calendar (one-way only)

---

## Prerequisites

- Google Cloud Console access
- iOS app bundle ID: `com.psst.Psst` (or your actual bundle ID)
- Admin access to configure OAuth consent screen

---

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click **Select a project** → **New Project**
3. Enter project name: `Psst Calendar Sync`
4. Click **Create**

---

## Step 2: Enable Google Calendar API

1. In your project, go to **APIs & Services** → **Library**
2. Search for "Google Calendar API"
3. Click **Google Calendar API**
4. Click **Enable**

---

## Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Select **External** user type (or **Internal** if using Google Workspace)
3. Click **Create**

### App Information
- **App name:** `Psst`
- **User support email:** Your email
- **Developer contact information:** Your email

### Scopes
1. Click **Add or Remove Scopes**
2. Manually add scope:
   ```
   https://www.googleapis.com/auth/calendar.events
   ```
3. Click **Update**

### Test Users (for External apps in testing)
1. Add test email addresses (trainers who will test the feature)
2. Click **Save and Continue**

---

## Step 4: Create OAuth 2.0 Client ID

1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth client ID**
3. Application type: **iOS**
4. Name: `Psst iOS App`
5. Bundle ID: `com.psst.Psst` (or your actual bundle ID)
6. Click **Create**

### Save Credentials

You'll receive a **Client ID** in this format:
```
505865284795-inggmn5im1kb68ogljqp6cp0oucap8r4.apps.googleusercontent.com
```

**Structure breakdown:**
- **Numeric part:** `505865284795-inggmn5im1kb68ogljqp6cp0oucap8r4`
- **Domain:** `.apps.googleusercontent.com`

**IMPORTANT:** Save the full Client ID - you'll need both parts for the next steps.

**Note about Client Secret:** iOS apps do not receive a client secret for native OAuth flows. Token refresh works without it for iOS clients.

---

## Step 5: Create Secrets.plist (Secure Configuration)

### Why Secrets.plist?

The app uses `SecretsManager` to load OAuth credentials from a `.plist` file that's excluded from Git. This prevents accidentally committing API keys to version control.

### Create Your Secrets File

1. Navigate to `Psst/Psst/` directory
2. Copy the example file:
   ```bash
   cp Secrets.plist.example Secrets.plist
   ```
3. Open `Secrets.plist` in Xcode or text editor

### Configure OAuth Credentials

Update the following keys in `Secrets.plist`:

#### GOOGLE_CLIENT_ID
```xml
<key>GOOGLE_CLIENT_ID</key>
<string>505865284795-inggmn5im1kb68ogljqp6cp0oucap8r4.apps.googleusercontent.com</string>
```
**Value:** Your full Client ID from Step 4

#### GOOGLE_CLIENT_SECRET
```xml
<key>GOOGLE_CLIENT_SECRET</key>
<string></string>
```
**Value:** Leave empty (iOS apps don't use client secrets for native OAuth)

#### GOOGLE_REDIRECT_URI
```xml
<key>GOOGLE_REDIRECT_URI</key>
<string>com.googleusercontent.apps.505865284795-inggmn5im1kb68ogljqp6cp0oucap8r4:/oauth2callback</string>
```
**Format:** `com.googleusercontent.apps.{NUMERIC_PART}:/oauth2callback`

**To construct this:**
1. Take your Client ID: `505865284795-inggmn5im1kb68ogljqp6cp0oucap8r4.apps.googleusercontent.com`
2. Extract numeric part: `505865284795-inggmn5im1kb68ogljqp6cp0oucap8r4`
3. Format: `com.googleusercontent.apps.505865284795-inggmn5im1kb68ogljqp6cp0oucap8r4:/oauth2callback`

#### GOOGLE_SCOPE
```xml
<key>GOOGLE_SCOPE</key>
<string>https://www.googleapis.com/auth/calendar.events email</string>
```
**Value:** Keep as-is (requests calendar events access and user email)

### Verify .gitignore

Ensure `Secrets.plist` is excluded from Git:
```bash
# Should already be in .gitignore
Psst/Psst/Secrets.plist
```

---

## Step 6: Update Info.plist URL Scheme

### Configure URL Scheme for OAuth Callback

The URL scheme in `Info.plist` **must match** your redirect URI format from Step 5.

Open `Psst/Psst/Info.plist` and verify/update:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>Google OAuth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.505865284795-inggmn5im1kb68ogljqp6cp0oucap8r4</string>
        </array>
        <key>CFBundleURLComment</key>
        <string>Google Calendar OAuth callback (PR #010C)</string>
    </dict>
</array>
```

**Replace** `505865284795-inggmn5im1kb68ogljqp6cp0oucap8r4` with **your** numeric Client ID part.

**Why this format?**
- Google OAuth requires iOS apps to use the reverse client ID format
- This prevents URL scheme conflicts with other apps
- Format: `com.googleusercontent.apps.{YOUR_NUMERIC_ID}`

---

## Step 7: Add Authorized Redirect URIs (Google Console)

1. Back in Google Cloud Console → **Credentials**
2. Click your OAuth 2.0 Client ID
3. Under **Authorized redirect URIs**, add:
   ```
   com.googleusercontent.apps.505865284795-inggmn5im1kb68ogljqp6cp0oucap8r4:/oauth2callback
   ```
   **Replace with your actual redirect URI from Secrets.plist**
4. Click **Save**

---

## Step 8: Test OAuth Flow

### Test the Connection

1. Build and run the Psst app on simulator/device
2. Go to **Settings** → **Calendar** → **Google Calendar**
3. Tap **Connect to Google Calendar**
4. Safari View should open with Google sign-in
5. Sign in with your Google account
6. Grant calendar permissions
7. You'll be redirected back to Psst
8. Status should show "Connected" with your email

### Test Event Sync

1. Go to **Calendar** → Create a new event
2. Fill in event details and save
3. Event should sync to Google Calendar within 5 seconds
4. Open Google Calendar app/web to verify
5. Event should appear with same title, time, and location

---

## Troubleshooting

### OAuth Error: "redirect_uri_mismatch"
**This is the most common issue!**

Check these three places **must match exactly**:

1. **Secrets.plist** → `GOOGLE_REDIRECT_URI`:
   ```
   com.googleusercontent.apps.505865284795-inggmn5im1kb68ogljqp6cp0oucap8r4:/oauth2callback
   ```

2. **Info.plist** → `CFBundleURLSchemes`:
   ```
   com.googleusercontent.apps.505865284795-inggmn5im1kb68ogljqp6cp0oucap8r4
   ```
   (Note: No `:/oauth2callback` suffix in Info.plist, just the scheme)

3. **Google Cloud Console** → Credentials → Authorized redirect URIs:
   ```
   com.googleusercontent.apps.505865284795-inggmn5im1kb68ogljqp6cp0oucap8r4:/oauth2callback
   ```

**All three must use YOUR actual numeric Client ID!**

### Error: "invalid_client"
- Verify Client ID is correct in `Secrets.plist` → `GOOGLE_CLIENT_ID`
- Check you're using the **iOS OAuth Client ID** (not the web client ID from Firebase)
- Verify OAuth consent screen is configured in Google Cloud Console

### Error: "access_denied"
- User denied permission during OAuth flow
- Have user try again and grant permissions

### Events Not Syncing
- Check Google Calendar connection status in Settings
- Verify scope includes: `https://www.googleapis.com/auth/calendar.events`
- Check Xcode console for sync errors
- Ensure event has valid start/end times and required fields

### Error: "Secrets.plist not found"
**Console warning:** `⚠️ [SecretsManager] Secrets.plist not found`

**Solution:**
1. Navigate to `Psst/Psst/` directory
2. Copy `Secrets.plist.example` to `Secrets.plist`
3. Fill in your OAuth credentials from Google Cloud Console
4. Rebuild the app in Xcode

### Rate Limiting (429 errors)
- Google Calendar API has quota limits
- Exponential backoff is implemented (5s, 10s, 30s retries)
- Consider implementing batch sync for bulk operations

---

## Security Best Practices

### Protect OAuth Credentials
- **DO NOT** commit `Secrets.plist` to Git (already in `.gitignore`)
- `Secrets.plist.example` is safe to commit (contains no real credentials)
- Each developer/environment should have their own `Secrets.plist`
- For production, consider backend token exchange for additional security

### Token Storage
- Refresh tokens stored in Firestore under `users/{userId}/integrations/googleCalendar`
- Access tokens refreshed on-demand (not stored permanently - they expire in 1 hour)
- Users can disconnect/revoke access anytime in Settings
- Token revocation also removes from Google's servers

### Scopes
- Only request `calendar.events` scope (not full calendar access)
- This allows creating/updating/deleting events only
- Cannot read other users' calendars or modify calendar settings
- `email` scope is used only to display connected account

---

## Production Checklist

Before launching to production:

- [ ] Create production `Secrets.plist` with production OAuth Client ID
- [ ] Verify `Secrets.plist` is in `.gitignore` (DO NOT commit)
- [ ] Update `Info.plist` URL scheme to match production Client ID
- [ ] Add production redirect URI to Google Cloud Console
- [ ] Configure OAuth consent screen for production (not testing mode)
- [ ] Add app verification (if required by Google for public release)
- [ ] Test OAuth flow on physical device (not just simulator)
- [ ] Verify URL scheme doesn't conflict with other apps
- [ ] Test token refresh after 1 hour (access token expiry)
- [ ] Test disconnect/reconnect flow
- [ ] Add error tracking for sync failures (Firebase Crashlytics)
- [ ] Monitor API quota usage in Google Cloud Console
- [ ] Document user-facing instructions for connecting Google Calendar
- [ ] Consider rate limiting for bulk event creation (avoid 429 errors)

---

## API Quota Limits

Google Calendar API free tier limits:
- **Queries per day:** 1,000,000
- **Queries per 100 seconds:** 3,000
- **Queries per 100 seconds per user:** 300

For typical usage:
- ~100 active trainers
- ~50 events/day per trainer
- = ~5,000 API calls/day (well within limits)

---

## Additional Resources

- [Google Calendar API Documentation](https://developers.google.com/calendar/api/guides/overview)
- [OAuth 2.0 for Mobile & Desktop Apps](https://developers.google.com/identity/protocols/oauth2/native-app)
- [Google API Console](https://console.cloud.google.com/)

---

## Support

For issues or questions:
- Check Firestore Rules allow reading/writing `integrations.googleCalendar`
- Review Xcode console logs for detailed error messages
- Verify Google Cloud project has Calendar API enabled
