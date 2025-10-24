# Gauntlet-02 🚀

A sophisticated iOS development project featuring **Psst** - a modern real-time messaging application built with SwiftUI and Firebase, powered by an intelligent multi-agent development system.

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)](https://developer.apple.com/ios/)
[![Firebase](https://img.shields.io/badge/Firebase-10.0+-yellow.svg)](https://firebase.google.com)
[![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue.svg)](https://developer.apple.com/xcode/)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Agent System](#agent-system)
- [Quick Start](#quick-start)
- [Development Workflow](#development-workflow)
- [Project Structure](#project-structure)
- [Psst iOS App](#psst-ios-app)
- [Firebase Configuration](#firebase-configuration)
- [Testing Strategy](#testing-strategy)
- [Custom Commands](#custom-commands)
- [Contributing](#contributing)

---

## 🎯 Overview

**Gauntlet-02** is a dual-purpose project:

1. **Psst Messaging App** - A production-ready iOS messaging application with:
   - Real-time one-on-one and group messaging
   - Firebase backend integration
   - Offline-first architecture
   - Push notifications
   - Modern SwiftUI interface

2. **Multi-Agent Development System** - An intelligent workflow system with specialized AI agents:
   - **Brenda** (Brief Creator) - Creates PR briefs from feature requirements
   - **Pam** (Planning Agent) - Generates detailed PRDs and TODO lists
   - **Caleb** (Coder Agent) - Implements features following PRDs

This system enables systematic, well-documented feature development with clear separation of concerns.

---

## 🤖 Agent System

### The Team

#### 🎨 Brenda - Brief Creator
Creates high-level PR briefs from feature requirements.

**Usage:**
```bash
# Mode 1: Single feature brief
/brenda authentication-system

# Mode 2: Document-based breakdown (reads docs and creates briefs)
/brenda AI-PRODUCT-VISION.md AI-BUILD-PLAN.md
/brenda Psst/docs/AI-PRODUCT-VISION.md  # Can use full or relative paths
```

**Output:**
- Adds entry to `Psst/docs/ai-briefs.md`
- Assigns next available PR number
- Defines dependencies, complexity, and phase

**How it works:**
- If you provide `.md` file paths, Brenda reads those docs and extracts all features
- If you provide a simple name, Brenda creates a brief for that feature
- Brenda can process multiple documents at once

---

#### 📝 Pam - Planning Agent
Transforms PR briefs into detailed PRDs and actionable TODO lists.

**Usage:**
```bash
/pam pr-5              # Create PRD, wait for review, then create TODO
/pam pr-5 yolo         # Create both PRD and TODO without stopping
```

**Output:**
- PRD: `Psst/docs/prds/pr-{N}-prd.md`
- TODO: `Psst/docs/todos/pr-{N}-todo.md`

**YOLO Mode:**
- `false` (default): Creates PRD → Waits for approval → Creates TODO
- `true`: Creates both documents without interruption

---

#### 👨‍💻 Caleb - Coder Agent
Implements features by following PRDs and TODO checklists.

**Usage:**
```bash
/caleb pr-3
```

**What Caleb Does:**
1. Reads PRD and TODO documents
2. Implements feature code (Services, Views, ViewModels, Models)
3. Creates all test files (Unit + UI tests)
4. Checks off TODO items as completed
5. Runs tests to verify functionality
6. Verifies with user before creating PR
7. Creates PR to `develop` branch when approved

---

### Complete Workflow Example

```bash
# 1. Create PR brief
/brenda user-authentication
→ Assigns PR #3

# 2. Plan the feature
/pam pr-3
→ Creates PRD
→ [Review and approve]
→ Creates TODO

# 3. Build the feature
/caleb pr-3
→ Implements all code
→ Creates tests
→ Checks off TODO items
→ Verifies with user
→ Creates PR when approved
```

---

## 🚀 Quick Start

### Prerequisites

- **Xcode** 15.0+
- **iOS 16.0+**
- **Firebase Account** (free tier)

### Setup

1. **Clone and open the project**
   ```bash
   git clone <repository-url>
   cd gauntlet-02/Psst
   open Psst.xcodeproj
   ```

2. **Get Firebase configuration** ⚠️ **REQUIRED**
   
   iOS projects use `.plist` files for configuration (like `.env` in web development):
   
   - Go to [Firebase Console](https://console.firebase.google.com/project/psst-fef89)
   - **Project Settings** → **Your Apps** → **iOS app**
   - Download `GoogleService-Info.plist`
   - Save it to: `gauntlet-02/Psst/GoogleService-Info.plist`

3. **Run the app**
   - In Xcode: Press `Cmd + R`
   - Or via terminal: `./run`

That's it! You should see the app launch in the simulator.

---

## 🔄 Development Workflow

### Branch Strategy

- **Base Branch:** `develop` (default)
- **Feature Branches:** `feat/pr-{number}-{feature-name}`
- **PR Target:** Always create PRs against `develop`, never `main`

### Feature Development Lifecycle

```
1. Brief Creation (Brenda)
   ├─ Define feature scope
   ├─ Assign PR number
   └─ Set dependencies & complexity

2. Planning (Pam)
   ├─ Write detailed PRD
   ├─ Review & approval
   └─ Generate TODO checklist

3. Implementation (Caleb)
   ├─ Read PRD + TODO
   ├─ Implement feature
   ├─ Create tests
   ├─ Check off tasks
   └─ Create PR

4. Review & Merge
   ├─ Code review
   ├─ Test verification
   └─ Merge to develop
```

---

## 📁 Project Structure

```
gauntlet-02/
├── Psst/                              # iOS Application
│   ├── Psst/                          # Main app bundle
│   │   ├── Services/                  # Business logic layer
│   │   │   ├── AuthService.swift
│   │   │   ├── ChatService.swift
│   │   │   ├── MessageService.swift
│   │   │   └── FirebaseService.swift
│   │   ├── Views/                     # SwiftUI views
│   │   │   ├── Authentication/
│   │   │   ├── ChatList/
│   │   │   ├── Conversation/
│   │   │   └── Components/
│   │   ├── ViewModels/                # MVVM view models
│   │   │   ├── AuthViewModel.swift
│   │   │   └── ChatListViewModel.swift
│   │   ├── Models/                    # Data models
│   │   │   ├── User.swift
│   │   │   ├── Chat.swift
│   │   │   └── Message.swift
│   │   └── Utilities/                 # Helpers & extensions
│   ├── PsstTests/                     # Unit tests (Swift Testing)
│   ├── PsstUITests/                   # UI tests (XCTest)
│   ├── agents/                        # Agent instructions
│   │   ├── caleb-agent.md
│   │   ├── pam-agent.md
│   │   ├── shared-standards.md
│   │   └── templates/
│   ├── docs/                          # Project documentation
│   │   ├── ai-briefs.md               # All PR descriptions
│   │   ├── AI-PRODUCT-VISION.md       # AI product vision (3 problems, personas)
│   │   ├── AI-BUILD-PLAN.md           # AI implementation plan (5 phases)
│   │   ├── architecture.md            # System architecture
│   │   ├── prds/                      # Individual PRDs
│   │   │   └── pr-{N}-prd.md
│   │   └── todos/                     # Individual TODOs
│   │       └── pr-{N}-todo.md
│   └── functions/                     # Firebase Cloud Functions
│       └── index.ts
└── README.md                          # This file
```

---

## 📱 Psst iOS App

### Overview

**Psst** is a modern real-time messaging application built with SwiftUI and Firebase, focusing on simplicity, reliability, and seamless user experience.

### Key Features

#### ✅ Phase 1: Foundation (Completed)
- User authentication (Email/Password & Google Sign-In)
- User profile management
- Firebase integration
- Basic UI structure

#### ✅ Phase 2: Core Messaging (Completed)
- One-on-one chat conversations
- Real-time message synchronization
- Message persistence
- Chat list view

#### 🚧 Phase 3: Enhanced Features (In Progress)
- Group chat support
- **Group member online indicators** (PR #004) ✨
  - Real-time presence status for all group members
  - Visual indicators (green/gray dots) next to profile photos
  - Sortable member list (online members first)
  - Tappable group header showing first 5 members
  - Automatic listener management (no memory leaks)
- Media sharing (images, files)
- Push notifications
- Read receipts
- Typing indicators

#### 📋 Phase 4: Advanced Features (Planned)
- Voice messages
- Message search
- Chat archiving
- Advanced settings

### Technical Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Backend:** Firebase
  - Authentication
  - Cloud Firestore
  - Realtime Database
  - Cloud Messaging
  - Cloud Functions
- **Architecture:** MVVM (Model-View-ViewModel)
- **Concurrency:** Swift async/await
- **Testing:** Swift Testing (unit) + XCTest (UI)

### Performance Targets

- **App load time:** < 2-3 seconds (cold start)
- **Message delivery:** < 100ms latency
- **Scrolling:** Smooth 60fps with 100+ messages
- **Tap response:** < 50ms
- **Offline support:** Full message persistence

---

## 🔥 Firebase Setup

This project uses Firebase for backend services. You need a `GoogleService-Info.plist` file to run the app.

### Getting the Config File

**For this project (psst-fef89):**
1. Go to [Firebase Console](https://console.firebase.google.com/project/psst-fef89/settings/general)
2. Download `GoogleService-Info.plist`
3. Save to `gauntlet-02/Psst/GoogleService-Info.plist`

**For your own Firebase project:**
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable: Authentication, Firestore, Realtime Database, Cloud Messaging
3. Add an iOS app with bundle ID: `gauntlet.Psst`
4. Download `GoogleService-Info.plist`

**Note:** This file is gitignored (like `.env` files) - you must download it yourself.

---

## 🧪 Testing Strategy

### Hybrid Testing Approach

**Unit Tests → Swift Testing Framework**
- Modern `@Test` syntax
- Readable test names: `"Sign Up With Valid Credentials Creates User"`
- Uses `#expect` for assertions
- Located in `PsstTests/`

**Example:**
```swift
@Test("User Service Creates New User Successfully")
func createUserTest() async throws {
    let user = try await userService.createUser(email: "test@example.com")
    #expect(user.email == "test@example.com")
}
```

**UI Tests → XCTest Framework**
- Traditional `XCTestCase` with `XCUIApplication`
- Function-based naming: `testLoginView_DisplaysCorrectly()`
- Uses `XCTAssert` for assertions
- Located in `PsstUITests/`

**Example:**
```swift
func testLoginView_DisplaysCorrectly() throws {
    let app = XCUIApplication()
    app.launch()
    
    XCTAssertTrue(app.buttons["Login"].exists)
    XCTAssertTrue(app.textFields["Email"].exists)
}
```

### Running Tests

```bash
# All tests
Cmd + U

# Specific test file
Cmd + U (with file open)

# Specific test
Click diamond icon next to test
```

### Test Coverage Requirements

- **Unit Tests:** All service methods
- **UI Tests:** Critical user flows (login, send message, create chat)
- **Integration Tests:** Firebase interactions
- **Performance Tests:** Message list scrolling, database queries

---

## 🛠️ Custom Commands

### `/caleb [pr-number]`
Activates Caleb (Coder Agent) to implement a feature.

```bash
/caleb pr-3
/caleb 3
```

### `/pam [pr-number] [yolo]`
Activates Pam (Planning Agent) to create PRD and TODO.

```bash
/pam pr-5        # Wait for PRD approval
/pam pr-5 yolo   # Create both without stopping
```

### `/brenda [feature-name]`
Activates Brenda (Brief Creator) to create PR brief.

```bash
/brenda authentication-system
```

### `/status`
Shows current PR status across all phases.

```bash
/status
```

**Output:**
- PRs with PRD only (needs TODO)
- PRs with PRD + TODO (ready for Caleb)
- PRs in progress (branch exists)
- PRs completed (merged to develop)

---

## 🎨 Code Quality Standards

### Swift Best Practices

- ✅ Explicit type annotations
- ✅ Proper use of SwiftUI property wrappers (`@State`, `@StateObject`, etc.)
- ✅ Small, focused functions
- ✅ Meaningful variable names
- ✅ No force unwrapping (`!`) without documentation

### Architecture Principles

- ✅ MVVM pattern for views
- ✅ Service layer for business logic
- ✅ Protocol-oriented design
- ✅ Dependency injection
- ✅ No business logic in views

### Threading Rules

**Main Thread:**
- All UI updates
- SwiftUI view rendering
- User interaction handling

**Background Thread:**
- Network requests
- Database operations
- File I/O
- Heavy computations

**Example:**
```swift
Task {
    // Network call on background
    let data = try await networkService.fetchData()
    
    // Update UI on main thread
    await MainActor.run {
        self.messages = data
    }
}
```

---

## 📖 Documentation

### Agent Documentation
- `Psst/agents/caleb-agent.md` - Coder agent
- `Psst/agents/pam-agent.md` - Planning agent  
- `Psst/agents/shared-standards.md` - Development standards

### Project Documentation  
- `Psst/docs/ai-briefs.md` - All PR descriptions
- `Psst/docs/AI-PRODUCT-VISION.md` - AI product vision
- `Psst/docs/AI-BUILD-PLAN.md` - AI implementation plan
- `Psst/docs/architecture.md` - System architecture

---

## 🤝 Contributing

### Development Process

1. **Create PR Brief** (via Brenda)
   ```bash
   /brenda your-feature-name
   ```

2. **Plan Feature** (via Pam)
   ```bash
   /pam pr-X
   ```

3. **Implement Feature** (via Caleb)
   ```bash
   /caleb pr-X
   ```

4. **Create Pull Request**
   - Target: `develop` branch
   - Include: PR description, test results, screenshots
   - Reference: PR brief, PRD, and TODO

5. **Code Review**
   - Verify tests pass
   - Check code quality
   - Validate against PRD requirements

6. **Merge**
   - Squash and merge to `develop`
   - Delete feature branch

### Commit Message Format

```
type(scope): subject

body (optional)

footer (optional)
```

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `test:` Tests
- `refactor:` Code refactoring
- `style:` Formatting changes
- `chore:` Build/config changes

**Example:**
```
feat(chat): Add group chat creation flow

Implements group chat creation with multi-user selection,
chat naming, and avatar upload.

Closes PR-8
```

---

## 🐛 Troubleshooting

**Build fails: "No such module 'Firebase'"**
- Clean build: `Cmd + Shift + K`
- Reset packages: `File → Packages → Reset Package Caches`

**"Could not configure Firebase"**
- Verify `GoogleService-Info.plist` is in `Psst/` directory
- Check it's added to Xcode target (File Inspector → Target Membership)

**Simulator issues**
- Reset simulator: `Device → Erase All Content and Settings`

---

## 📊 Project Status

### Current Phase: **Phase 3** (Enhanced Features)

**Completed:**
- ✅ PR-1 to PR-10: Foundation & Core Messaging
- ✅ Authentication system
- ✅ One-on-one chat
- ✅ Message persistence
- ✅ Real-time synchronization

**In Progress:**
- 🚧 PR-15: Group chat support
- 🚧 PR-16: Media sharing
- 🚧 PR-17: Push notifications

**Upcoming:**
- 📋 Read receipts
- 📋 Typing indicators
- 📋 Voice messages
- 📋 Message search

---

## 📝 License

Copyright © 2025

---

## 🙏 Acknowledgments

- **Firebase** - Backend infrastructure
- **SwiftUI** - Modern UI framework
- **Signal Protocol** - Architecture inspiration

---

## 📞 Support

For questions, issues, or feature requests:
1. Check existing documentation in `Psst/docs/`
2. Review agent instructions in `Psst/agents/`
3. Create an issue with detailed description

---

**Built with ❤️ using SwiftUI and Firebase**
