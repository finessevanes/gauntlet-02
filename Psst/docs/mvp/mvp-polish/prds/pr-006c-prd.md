# PRD: Settings Redesign - iOS Grouped List

**Feature**: Settings Tab Redesign

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam (Planning Agent)

**Target Release**: Phase 1 - MVP Polish

**Links**: 
- PR Brief: `Psst/docs/pr-briefs.md` (PR #006C)
- TODO: `Psst/docs/todos/pr-006c-todo.md` (to be created)
- UX Spec: `Psst/docs/ux-specs/pr-006-ux-spec.md` (section 4)
- Dependencies: PR #006B (main app polish - establishes tab bar styling)

---

## 1. Summary

Complete redesign of the Settings tab from a basic centered placeholder to a professional iOS-style grouped list following native iOS Settings app patterns. This creates a polished, functional settings screen that completes the app-wide design system overhaul.

---

## 2. Problem & Goals

**Problem**: 
The current Settings tab is a basic placeholder with centered text and a logout button. It doesn't match the professional quality of the rest of the app after PR #006A and #006B. Users expect a proper Settings screen with organized sections, navigation to sub-screens, and iOS-native patterns. The current implementation feels incomplete and unprofessional.

**Why Now**: 
This is the final piece of the app-wide design system overhaul (PR #006A → #006B → #006C). After enhancing the auth screens and main app, Settings is the last major screen that needs polish. It's relatively simple (no complex logic) but essential for completing the professional, cohesive app experience.

**Goals** (ordered, measurable):
- [ ] **G1** — Replace placeholder with professional iOS-style grouped list
- [ ] **G2** — Implement user info section at top with profile photo and email
- [ ] **G3** — Create "Account" and "Support" sections with proper navigation
- [ ] **G4** — Maintain existing logout functionality with improved styling
- [ ] **G5** — Complete the unified design system across all major app screens

---

## 3. Non-Goals / Out of Scope

To keep this PR focused on core Settings UI:

- [ ] **Not implementing** actual settings functionality (notifications, privacy, etc.) - just UI structure
- [ ] **Not adding** notifications settings logic (placeholder navigation only)
- [ ] **Not adding** help/support content (placeholder views for now)
- [ ] **Not adding** about screen content (placeholder for now)
- [ ] **Not implementing** account settings logic beyond Edit Profile (already exists)
- [ ] **Not adding** app version, terms of service, privacy policy (defer to Phase 2)
- [ ] **Not adding** theme switching or appearance settings (defer to Phase 2)

---

## 4. Success Metrics

**User-visible**:
- Settings screen looks professional and matches iOS native apps
- Clear navigation structure with organized sections
- User can easily find logout button
- Consistent with rest of app (auth, main app from PR #006A/B)

**System** (see `Psst/agents/shared-standards.md`):
- Settings screen renders in <100ms
- Navigation to sub-screens <50ms
- Logout function completes in <200ms
- No UI blocking during logout

**Quality**:
- 0 visual regressions
- Logout functionality works identically
- All acceptance gates pass
- Clean UI on all device sizes

---

## 5. Users & Stories

**Primary Users**: App users managing account settings and accessing support

**User Stories**:

1. **As a user**, I want a professional Settings screen that matches iOS standards so that I feel confident navigating app settings.

2. **As a user**, I want to see my profile info at the top of Settings so that I know which account I'm managing.

3. **As a user**, I want clearly organized sections (Account, Support) so that I can quickly find the setting I need.

4. **As a user**, I want a clearly marked logout button so that I can sign out when needed.

---

## 6. Experience Specification (UX)

### Entry Points

**Settings Tab**:
- Accessed via tab bar (3rd tab, likely "Settings" or using gear icon)
- Main view: Settings list with sections

### Visual Behavior

**Settings Screen - iOS Grouped List**:

**Before (Current)**:
```
┌─────────────────────────┐
│      Settings           │
│                         │
│                         │
│                         │
│    Settings coming      │  ← Placeholder text
│       soon...           │
│                         │
│                         │
│   [    Log Out    ]     │  ← Basic button
│                         │
└─────────────────────────┘
```

**After (New)**:
```
┌─────────────────────────┐
│      Settings           │
│                         │
│ [Photo] Sarah M         │  ← User info header
│ sarah@email.com         │
│                         │
│ Account                 │  ← Section header
│ ┌─────────────────────┐ │
│ │ 🔔 Notifications  > │ │  ← NavigationLink
│ └─────────────────────┘ │
│                         │
│ Support                 │  ← Section header
│ ┌─────────────────────┐ │
│ │ ❓ Help & Support > │ │  ← NavigationLink
│ │ ℹ️  About         > │ │  ← NavigationLink
│ └─────────────────────┘ │
│                         │
│   [    Log Out    ]     │  ← Red destructive button
└─────────────────────────┘
```

**Layout Structure**:

1. **User Info Section** (top):
   - Profile photo: 60pt circular avatar (left)
   - User name: `.headline` + `.bold`
   - User email: `.subheadline` + `.secondary`
   - Padding: 16pt around, not inside a grouped box
   - Background: `.secondarySystemBackground`

2. **Account Section**:
   - Section header: "Account" (`.footnote` + `.uppercase` + `.secondary`)
   - **Notifications** row:
     - SF Symbol: `bell.circle` (leading)
     - Label: "Notifications"
     - Chevron: `>` (trailing)
     - Action: Navigate to placeholder `NotificationsSettingsView`
   - **Note**: Edit Profile is in Profile Tab only (no duplication)

3. **Support Section**:
   - Section header: "Support" (`.footnote` + `.uppercase` + `.secondary`)
   - **Help & Support** row:
     - SF Symbol: `questionmark.circle` (leading)
     - Label: "Help & Support"
     - Chevron: `>` (trailing)
     - Action: Navigate to placeholder `HelpSupportView`
   - **About** row:
     - SF Symbol: `info.circle` (leading)
     - Label: "About"
     - Chevron: `>` (trailing)
     - Action: Navigate to placeholder `AboutView`

4. **Logout Button** (bottom):
   - Style: `.borderedProminent` with `.red` color (destructive)
   - Text: "Log Out"
   - Full width with 24pt horizontal padding
   - 32pt top padding (space from Support section)
   - Centered
   - Action: Existing logout functionality

**iOS List Styling**:

- Use `List` with `.listStyle(.insetGrouped)`
- Sections use `.listSectionHeader` for headers
- Rows use `Label` with SF Symbols
- `NavigationLink` for rows that navigate
- System colors: `.label`, `.secondaryLabel`, `.tertiaryLabel`
- Backgrounds: `.systemBackground`, `.secondarySystemBackground`

**Visual Details**:

- **SF Symbols**: 20pt, `.symbolRenderingMode(.hierarchical)`
- **Row height**: 44pt minimum (iOS standard)
- **Spacing**: 8pt between sections, 16pt section padding
- **Dividers**: iOS system dividers between rows
- **Chevrons**: iOS standard `>` chevron for navigation

### Sub-Screens (Placeholders)

**NotificationsSettingsView** (placeholder):
```swift
struct NotificationsSettingsView: View {
    var body: some View {
        List {
            Section {
                Text("Notification settings coming soon")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
    }
}
```

**HelpSupportView** (placeholder):
```swift
struct HelpSupportView: View {
    var body: some View {
        List {
            Section {
                Text("Help & support resources coming soon")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.large)
    }
}
```

**AboutView** (placeholder):
```swift
struct AboutView: View {
    var body: some View {
        List {
            Section {
                Text("App information coming soon")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.large)
    }
}
```

### Loading/Disabled/Error States

**Loading State**:
- User info section: Skeleton (placeholder photo + text)
- List sections: Show with disabled appearance
- Logout button: Visible but disabled

**Error State**:
- If user data fails to load: Show "Unable to load settings" with retry
- List structure still visible
- Logout always available (fallback)

**Logout Loading**:
- Button shows `ProgressView()` when logging out
- Button disabled, text: "Logging out..."
- On success: Navigate to LoginView
- On error: Show alert with error message

### Performance Targets

See `Psst/agents/shared-standards.md` for general targets. Specific to this feature:

- **Screen render**: <100ms to display Settings screen
- **Navigation**: <50ms to sub-screens
- **Logout**: <200ms to complete (Firebase signout)
- **Smooth animations**: 60fps for navigation transitions

---

## 7. Functional Requirements (Must/Should)

### Must-Have Requirements

**R1**: Settings screen MUST use iOS-native grouped list (`List` with `.insetGrouped`)
- **Acceptance Gate**: Settings screen uses `List` component with `.listStyle(.insetGrouped)`

**R2**: User info section MUST display current user's photo and email at top
- **Acceptance Gate**: User's profile photo (60pt) and email visible at top of Settings screen

**R3**: "Account" section MUST include Notifications navigation item
- **Acceptance Gate**: Account section has Notifications row, tapping navigates to NotificationsSettingsView
- **Note**: Edit Profile is in Profile Tab only (no duplication in Settings)

**R4**: "Support" section MUST include Help & Support and About navigation items
- **Acceptance Gate**: Two rows in Support section, tapping navigates to respective screens

**R5**: Logout button MUST maintain existing functionality (Firebase signout)
- **Acceptance Gate**: Tap "Log Out" → User signed out → Returns to LoginView

**R6**: Logout button MUST use destructive styling (red, prominent)
- **Acceptance Gate**: Logout button is red with `.borderedProminent` style

**R7**: All rows MUST use SF Symbols and Labels for consistent styling
- **Acceptance Gate**: Each row has SF Symbol icon (leading) and label with chevron (trailing)

### Should-Have Requirements

**R8**: Placeholder views SHOULD have proper navigation structure
- **Acceptance Gate**: Notifications, Help, About screens have nav title and back button

**R9**: Settings screen SHOULD handle user data loading errors gracefully
- **Acceptance Gate**: If user fetch fails, show error message but keep Settings structure accessible

**R10**: Section headers SHOULD use iOS standard styling
- **Acceptance Gate**: "Account" and "Support" headers use `.footnote` + `.uppercase` + `.secondary`

---

## 8. Data Model

**No data model changes required.** Uses existing user data.

**Existing Models Used**:
- `User` - for user info section (photo, name, email)

---

## 9. API / Service Contracts

**No new service methods required.** Uses existing services.

**Existing Services Used**:

```swift
// From AuthenticationService (no changes)
func signOut() throws

// From UserService (no changes)
func getCurrentUser() async throws -> User

// From AuthViewModel (no changes)
@Published var currentUser: User?
func logout() throws
```

---

## 10. UI Components to Create/Modify

### Files to Modify/Create

**Settings Tab** (1 file to modify):
- `Views/Settings/SettingsView.swift` — Complete redesign from placeholder to iOS list

**Placeholder Views** (3 new files):
- `Views/Settings/NotificationsSettingsView.swift` — Placeholder for notifications settings (new)
- `Views/Settings/HelpSupportView.swift` — Placeholder for help/support (new)
- `Views/Settings/AboutView.swift` — Placeholder for about screen (new)

**Total**: 1 modified, 3 new = 4 files

### Components Breakdown

**SettingsView.swift** (complete redesign):

```swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isLoggingOut = false
    @State private var showLogoutError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                // User Info Section (not in a section, custom header)
                userInfoSection
                
                // Account Section
                Section(header: Text("Account")) {
                    NavigationLink(destination: NotificationsSettingsView()) {
                        Label("Notifications", systemImage: "bell.circle")
                    }
                }
                
                // Support Section
                Section(header: Text("Support")) {
                    NavigationLink(destination: HelpSupportView()) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        Label("About", systemImage: "info.circle")
                    }
                }
                
                // Logout Button Section
                Section {
                    logoutButton
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Logout Error", isPresented: $showLogoutError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var userInfoSection: some View {
        HStack(spacing: 16) {
            // Profile Photo
            UserAvatarView(
                user: authViewModel.currentUser,
                size: 60
            )
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(authViewModel.currentUser?.displayName ?? "User")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(authViewModel.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .listRowBackground(Color(.secondarySystemBackground))
    }
    
    private var logoutButton: some View {
        Button(action: handleLogout) {
            if isLoggingOut {
                HStack {
                    Spacer()
                    ProgressView()
                    Text("Logging out...")
                        .padding(.leading, 8)
                    Spacer()
                }
            } else {
                HStack {
                    Spacer()
                    Text("Log Out")
                    Spacer()
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .disabled(isLoggingOut)
        .listRowBackground(Color.clear)
    }
    
    private func handleLogout() {
        isLoggingOut = true
        
        do {
            try authViewModel.logout()
            // Navigation handled by AuthViewModel
        } catch {
            errorMessage = error.localizedDescription
            showLogoutError = true
            isLoggingOut = false
        }
    }
}
```

**NotificationsSettingsView.swift** (new):
```swift
import SwiftUI

struct NotificationsSettingsView: View {
    var body: some View {
        List {
            Section {
                Text("Notification settings coming soon")
                    .foregroundColor(.secondary)
                    .font(.body)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
    }
}
```

**HelpSupportView.swift** (new):
```swift
import SwiftUI

struct HelpSupportView: View {
    var body: some View {
        List {
            Section {
                Text("Help & support resources coming soon")
                    .foregroundColor(.secondary)
                    .font(.body)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.large)
    }
}
```

**AboutView.swift** (new):
```swift
import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                Text("App information coming soon")
                    .foregroundColor(.secondary)
                    .font(.body)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.large)
    }
}
```

---

## 11. Integration Points

### Existing Integrations (No Changes)
- **Firebase Authentication**: Logout functionality (existing)
- **UserService**: Current user data (existing)
- **AuthViewModel**: State management (existing)
- **EditProfileView**: Existing profile editing screen (navigation only)

### Design Consistency
- Uses design system from PR #006A and #006B:
  - Color: `.blue` accent (tab bar), `.red` destructive (logout)
  - Typography: iOS text styles (`.headline`, `.subheadline`)
  - Spacing: 8pt/16pt/24pt grid
  - iOS-native patterns: `.insetGrouped` list, `NavigationLink`, `Label`

---

## 12. Testing Plan & Acceptance Gates

### Configuration Testing
- [ ] Firebase Authentication connected (logout works)
- [ ] UserService can fetch current user
- [ ] AuthViewModel provides current user data

### Visual Testing
- [ ] Settings uses `.insetGrouped` list style
- [ ] User info section at top with photo (60pt) and email
- [ ] "Account" section header displays correctly
- [ ] Notifications row with icon and chevron
- [ ] "Support" section header displays correctly
- [ ] Help & Support row with icon and chevron
- [ ] About row with icon and chevron
- [ ] Logout button is red and prominent
- [ ] SF Symbols display at 20pt, hierarchical mode
- [ ] Dark Mode: All sections adapt correctly
- [ ] Edit Profile NOT in Settings (only in Profile tab)

### Happy Path Testing
- [ ] Gate: Tap "Notifications" → Navigates to NotificationsSettingsView (placeholder)
- [ ] Gate: Tap "Help & Support" → Navigates to HelpSupportView (placeholder)
- [ ] Gate: Tap "About" → Navigates to AboutView (placeholder)
- [ ] Gate: Tap "Log Out" → User logged out → Returns to LoginView in <200ms
- [ ] Gate: Back navigation works from all sub-screens
- [ ] Gate: Verify Edit Profile is NOT in Settings (only in Profile tab)

### Edge Cases Testing
- [ ] User data fails to load → Show error, Settings structure still accessible
- [ ] Logout fails (network error) → Show alert with error message
- [ ] Multiple rapid taps on logout → Prevent duplicate logout attempts
- [ ] No profile photo → Show initials or placeholder
- [ ] Very long user name/email → Text truncates properly

### Multi-Device Testing
- [ ] iPhone SE → List layout works, rows readable
- [ ] iPhone 15 → List layout perfect
- [ ] iPhone 15 Pro Max → List layout perfect, no awkward spacing
- [ ] Landscape → List adapts (stacks or split view)
- [ ] Dark Mode → All colors and contrasts correct

### Performance Testing
- [ ] Settings screen renders in <100ms
- [ ] Navigation to sub-screens <50ms
- [ ] Logout completes in <200ms
- [ ] Smooth 60fps navigation animations
- [ ] No memory leaks

### Regression Testing
- [ ] EditProfileView still accessible from Profile tab (existing functionality)
- [ ] Logout works identically to before
- [ ] Tab navigation works
- [ ] User data still loads correctly

---

## 13. Definition of Done

- [ ] SettingsView redesigned with iOS grouped list
- [ ] User info section implemented (photo + name + email)
- [ ] Account section with Notifications (Edit Profile in Profile tab only)
- [ ] Support section with Help & Support and About
- [ ] Logout button styled as destructive (red)
- [ ] Placeholder views created (Notifications, Help, About)
- [ ] Navigation to all sub-screens works
- [ ] Logout functionality works (0 regressions)
- [ ] Dark Mode supported
- [ ] Manual testing completed (all gates pass)
- [ ] Code review completed
- [ ] Design reviewed and approved (matches UX spec)

---

## 14. Risks & Mitigations

**Risk**: User data loading fails, Settings looks broken
- **Mitigation**: Show placeholder data; keep Settings structure visible even on error

**Risk**: Logout button too easy to tap accidentally
- **Mitigation**: Red color signals danger; consider adding confirmation alert (nice-to-have)

**Risk**: Placeholder views disappoint users (look too empty)
- **Mitigation**: Clear messaging: "Coming soon"; better than no Settings at all

**Risk**: List style looks different on older iOS versions
- **Mitigation**: `.insetGrouped` is standard since iOS 14+; acceptable

---

## 15. Rollout & Telemetry

**Feature Flag**: No

**Rollout Strategy**: 
- Deploy as part of PR #006C
- Completes design system overhaul (006A → 006B → 006C)
- No gradual rollout needed

**Manual Validation**:
- Test all navigation flows
- Test logout on physical device
- Verify Dark Mode
- Screenshot before/after for documentation

**Success Indicators**:
- 0 Settings-related bug reports
- Logout works without issues
- Completes unified app design system
- Professional appearance matches iOS standards

---

## 16. Open Questions

**Q1**: Should logout have a confirmation alert ("Are you sure?")?
- **Answer**: Not required for MVP; red color signals danger; can add in Phase 2 if users accidentally logout

**Q2**: Should user info section be tappable (navigate to Profile tab)?
- **Answer**: No, keep it as static info; Edit Profile navigation is sufficient

**Q3**: Should we show app version in About view placeholder?
- **Answer**: Yes, nice-to-have for About view (can add simple version text)

**Q4**: Should Settings be scrollable on small devices?
- **Answer**: Yes, List is automatically scrollable; test on iPhone SE

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future phases:

**Phase 2 - Settings Functionality**:
- [ ] Notification settings implementation (push, in-app, sounds)
- [ ] Privacy settings (read receipts, online status visibility)
- [ ] Appearance settings (theme, text size, reduce motion)
- [ ] Data & storage settings (cache management, data usage)
- [ ] Account settings (change password, delete account)

**Phase 2 - Support Content**:
- [ ] Help articles and FAQs
- [ ] Contact support form
- [ ] Report a problem
- [ ] In-app feedback mechanism

**Phase 2 - About Content**:
- [ ] App version and build number
- [ ] Terms of Service
- [ ] Privacy Policy
- [ ] Open source licenses
- [ ] Credits and acknowledgments

**Nice-to-Haves**:
- [ ] Logout confirmation alert
- [ ] Settings search
- [ ] Quick actions (3D Touch)
- [ ] Settings backup/sync

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - User sees professional Settings screen with organized sections and can logout

2. **Primary user and critical action?**
   - All users accessing Settings to manage account or logout

3. **Must-have vs nice-to-have?**
   - Must: iOS list, user info, sections, navigation, logout
   - Nice: Logout confirmation, settings content, about info

4. **Real-time requirements?**
   - None (Settings is mostly static UI)

5. **Performance constraints?**
   - Screen render <100ms, navigation <50ms, logout <200ms

6. **Error/edge cases to handle?**
   - User data load failure, logout errors, no profile photo

7. **Data model changes?**
   - None (uses existing User model)

8. **Service APIs required?**
   - None (uses existing AuthenticationService, UserService)

9. **UI entry points and states?**
   - Entry: Settings tab from tab bar
   - States: Default, loading, error, logout loading

10. **Security/permissions implications?**
    - None (logout uses existing Firebase auth)

11. **Dependencies or blocking integrations?**
    - Depends on: PR #006B (tab bar styling)
    - Blocks: None (final PR in design system overhaul)

12. **Rollout strategy and metrics?**
    - Deploy directly, completes PR #006 series
    - Success: Professional Settings UI, 0 logout regressions

13. **What is explicitly out of scope?**
    - Settings functionality implementation, support content, about content, confirmation alerts

---

**End of PRD**

