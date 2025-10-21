# Psst - Real-Time Messaging App

A modern iOS messaging application built with SwiftUI and Firebase.

## Firebase Configuration

This project uses Firebase for backend services including Authentication, Firestore Database, Realtime Database, and Cloud Messaging.

### Firebase Project Details

- **Project Name**: psst
- **Project ID**: psst-fef89
- **Project Number**: 505865284795

### Required Firebase Services

The following Firebase services must be enabled in the Firebase Console:

- ✅ **Firebase Authentication** - User sign-up, login, and session management
- ✅ **Cloud Firestore** - Primary database for messages, chats, and user data
- ✅ **Realtime Database** - Used for presence indicators and typing status
- ✅ **Cloud Messaging (FCM)** - Push notifications for new messages

### Setup Instructions

1. **Download GoogleService-Info.plist** ⚠️ **REQUIRED**
   - Go to [Firebase Console](https://console.firebase.google.com) → Project `psst` (psst-fef89)
   - Navigate to Project Settings → Your Apps → iOS app
   - Download `GoogleService-Info.plist`
   - Place it at: `Psst/Psst/GoogleService-Info.plist`
   - **Note**: This file is in `.gitignore` for security - you must download it yourself

2. **Install Firebase SDK via Swift Package Manager**
   - Open `Psst.xcodeproj` in Xcode
   - Go to `File` → `Add Package Dependencies`
   - Enter URL: `https://github.com/firebase/firebase-ios-sdk`
   - Use the latest stable version (10.x or higher)
   - Select the following packages:
     - `FirebaseAuth`
     - `FirebaseFirestore`
     - `FirebaseDatabase`
     - `FirebaseMessaging`
   - Add all packages to the `Psst` target

3. **Verify Firebase Initialization**
   - Build and run the app (Cmd+R)
   - Check Xcode console for: `✅ Firebase configured successfully`
   - Verify the Project ID matches: `psst-fef89`

### Firebase Architecture

- **FirebaseService.swift** - Centralized Firebase configuration and service access
- **Offline Persistence** - Firestore offline persistence is enabled for offline-first architecture
- **Cache Size** - Unlimited cache size to support extensive offline usage

### Troubleshooting

**Issue**: Build fails with "No such module 'Firebase'"
- **Solution**: Ensure Firebase SDK is added via Swift Package Manager to the Psst target

**Issue**: Console shows "Could not configure Firebase"
- **Solution**: Verify `GoogleService-Info.plist` is in the correct location and added to the Psst target

**Issue**: Firebase Console shows app as "not connected"
- **Solution**: Run the app at least once and check for initialization logs in Xcode console

## Development

### Quick Start - Build & Run

Run the app on iOS Simulator **without opening Xcode**:

```bash
# Run on iPhone 17 Pro
./run iphone17

# Run on default simulator (iPhone 15 Pro)
./run

# List all available simulators
./run list
```

See [`scripts/README.md`](scripts/README.md) for more options and troubleshooting.

### Branch Strategy

- **Base Branch**: `develop`
- **Feature Branches**: `feat/pr-{number}-{feature-name}`
- **PR Target**: Always create PRs against `develop`, never `main`

### Requirements

- Xcode 15.0+
- iOS 16.0+
- Swift 5.9+
- Xcode Command Line Tools (for running via `./run` scripts)

## Project Structure

```
gauntlet-02/
├── Psst/
│   ├── Psst/
│   │   ├── Services/
│   │   │   └── FirebaseService.swift
│   │   ├── PsstApp.swift
│   │   └── GoogleService-Info.plist
│   ├── PsstTests/
│   └── PsstUITests/
├── Psst/
│   ├── agents/          # Agent instructions
│   ├── docs/            # PRDs, TODOs, and briefs
└── README.md
```

## Testing

### Test Framework Strategy

This project uses a **hybrid testing approach** combining modern and traditional frameworks:

**Unit Tests → Swift Testing Framework**
- Modern `@Test` syntax with custom display names
- Tests appear with readable names in test navigator (e.g., "Sign Up With Valid Credentials Creates User")
- Uses `#expect` for assertions
- Located in `PsstTests/`

**UI Tests → XCTest Framework**
- Traditional `XCTestCase` with `XCUIApplication`
- Function-based naming (e.g., `testLoginView_DisplaysCorrectly()`)
- Uses `XCTAssert` for assertions
- Located in `PsstUITests/`

### Why Different Frameworks?

- **Swift Testing** provides better readability and modern syntax for unit tests
- **XCTest** remains the industry standard for UI tests due to `XCUIApplication` lifecycle requirements

### Running Tests

Run tests using Xcode:
- **All Tests**: Cmd+U
- **Specific Test**: Click diamond icon next to test name
- **Performance Tests**: Included in test suite

See `Psst/agents/test-template.md` for detailed testing patterns.

## License

Copyright © 2025
