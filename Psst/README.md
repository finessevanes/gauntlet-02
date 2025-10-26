# Psst

A secure messaging application built with SwiftUI and Firebase.

---

## Overview

Psst is an iOS messaging app featuring:

- Real-time messaging with Firebase
- AI-powered chat capabilities
- Secure authentication
- Group and direct messaging
- Read receipts and typing indicators
- Message search and filtering

---

## Tech Stack

- **Frontend**: SwiftUI, Combine
- **Backend**: Firebase (Firestore, Realtime Database, Cloud Functions, Storage)
- **AI Integration**: OpenAI API, Google Vertex AI
- **Architecture**: MVVM pattern with service layer
- **Deployment**: Fastlane automation

---

## Development Setup

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- CocoaPods or Swift Package Manager
- Firebase account
- Apple Developer account

### Getting Started

```bash
# Clone the repository
git clone git@github.com:finessevanes/gauntlet-02.git
cd Psst

# Open in Xcode
open Psst.xcodeproj

# Build and run (⌘R)
```

### Configuration

1. Add `GoogleService-Info.plist` to the Psst directory (download from Firebase Console)
2. Create `Config.swift` from `Config.example.swift` and add your API keys
3. Ensure Firebase services are configured in Firebase Console

---

## Deployment

This project uses **Fastlane** for automated iOS deployments to TestFlight and App Store.

### Quick Start

**Deploy to TestFlight:**
```bash
fastlane beta
```

**Deploy to App Store:**
```bash
fastlane release
```

**Run tests:**
```bash
fastlane test
```

### First-Time Setup

For detailed Fastlane setup instructions, including:
- Installing Fastlane
- Creating App Store Connect API keys
- Configuring Match for code signing
- Team member onboarding
- Troubleshooting

See **[fastlane/README.md](fastlane/README.md)** for complete documentation.

### New Team Members

```bash
# 1. Install Fastlane
brew install fastlane

# 2. Create .env from template
cp fastlane/.env.example fastlane/.env

# 3. Add credentials (get from team password manager)
nano fastlane/.env

# 4. Sync certificates
fastlane match_appstore --readonly

# 5. Deploy!
fastlane beta
```

---

## Project Structure

```
Psst/
├── Psst/                    # iOS app source code
│   ├── Models/             # Data models
│   ├── Views/              # SwiftUI views
│   ├── ViewModels/         # View models (MVVM)
│   ├── Services/           # Business logic layer
│   └── Utilities/          # Helper functions
├── functions/              # Firebase Cloud Functions (TypeScript)
├── docs/                   # Project documentation
│   ├── prds/              # Product requirement documents
│   ├── todos/             # Implementation checklists
│   └── ai-briefs.md       # Feature briefs
├── agents/                 # AI agent configurations
├── fastlane/              # Deployment automation
└── Psst.xcodeproj         # Xcode project
```

---

## Architecture

### iOS App (MVVM)

- **Models**: Swift structs representing data (Message, User, Chat)
- **Views**: SwiftUI views for UI
- **ViewModels**: Observable objects managing state
- **Services**: Business logic (AuthService, ChatService, MessageService)

### Backend (Firebase)

- **Firestore**: Primary database for messages, chats, users
- **Realtime Database**: Presence and typing indicators
- **Cloud Functions**: TypeScript functions for AI integration, background tasks
- **Storage**: Media files (images, videos, audio)

For detailed architecture documentation, see [docs/architecture.md](docs/architecture.md).

---

## Development Workflow

### Feature Development

The project uses a structured agent-based workflow:

1. **Brenda** creates feature briefs → `docs/ai-briefs.md`
2. **Pam** creates PRDs and TODOs → `docs/prds/` and `docs/todos/`
3. **Claudia** designs UI/UX (optional) → `docs/ux-specs/`
4. **Caleb** implements features → Code changes
5. Deploy via Fastlane → TestFlight/App Store

See [CLAUDE.md](CLAUDE.md) for complete agent workflow documentation.

### Git Workflow

- **Main branch**: `main` (production)
- **Development branch**: `develop` (integration)
- **Feature branches**: `feat/pr-{number}-{feature-name}`

All pull requests target `develop`, not `main`.

---

## Testing

### Manual Testing

Current testing strategy focuses on user-centric manual validation:

- **Happy Path**: Main user flow works end-to-end
- **Edge Cases**: Non-standard inputs handled gracefully
- **Error Handling**: Offline/timeout/invalid input show clear messages
- **Multi-Device**: Real-time sync tested across devices

See [docs/testing-strategy.md](docs/testing-strategy.md) for details.

### Running Tests

```bash
# Via Fastlane (recommended)
fastlane test

# Via Xcode
# Press ⌘U or Product → Test
```

---

## Firebase Functions

Backend TypeScript functions for AI and automation.

### Deploy Functions

```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Build TypeScript
npm run build

# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:chatWithAI
```

See [functions/README.md](functions/README.md) for function documentation.

---

## Contributing

### Code Standards

- **Swift**: Follow shared-standards.md for MVVM, async/await, thread safety
- **TypeScript**: Use proper types, no `any`, TSDoc comments for exported functions
- **Testing**: Manual validation required for all PRs
- **Performance**: Maintain 60fps UI, <100ms message delivery

See [agents/shared-standards.md](agents/shared-standards.md) for complete standards.

### Submitting Changes

1. Create feature branch from `develop`
2. Implement feature following PRD/TODO
3. Test thoroughly (see testing-strategy.md)
4. Create PR targeting `develop`
5. Request review
6. Merge after approval

---

## Documentation

- **[CLAUDE.md](CLAUDE.md)**: Agent workflow and slash commands
- **[fastlane/README.md](fastlane/README.md)**: Deployment setup and usage
- **[docs/testing-strategy.md](docs/testing-strategy.md)**: Testing approach
- **[docs/architecture.md](docs/architecture.md)**: System architecture
- **[agents/shared-standards.md](agents/shared-standards.md)**: Code quality standards

---

## Support

For questions or issues:

- Check documentation in `docs/` directory
- See [fastlane/README.md](fastlane/README.md) for deployment issues
- Review [agents/shared-standards.md](agents/shared-standards.md) for code standards

---

## License

[Add license information]

---

## Team

Built with Claude Code and Fastlane automation.
