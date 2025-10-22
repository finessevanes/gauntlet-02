# PRD: User Profile Editing

**Feature**: user-profile-editing

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam

**Target Release**: Phase 4

**Links**: [PR Brief], [TODO], [Designs], [Tracking Issue]

---

## 1. Summary

Build a comprehensive profile editing screen where users can update their display name and profile picture with real-time synchronization across all app screens. This feature enables users to personalize their identity in the messaging app with seamless photo uploads to Firebase Storage and instant profile updates.

---

## 2. Problem & Goals

**User Problem**: Users need a way to customize their profile information (name and photo) to establish their identity in conversations and make the app feel personal.

**Why Now**: After completing core messaging functionality, users need profile customization to complete the personal messaging experience.

**Goals (ordered, measurable):**
- [ ] G1 — Users can update display name with validation (2-50 characters)
- [ ] G2 — Users can upload and change profile photos with compression
- [ ] G3 — Profile changes sync in real-time across all app screens (<100ms)
- [ ] G4 — Image upload completes in <3 seconds for typical photos

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing profile photo deletion (users can upload new photo to replace)
- [ ] Not supporting video uploads (photos only)
- [ ] Not implementing profile photo cropping/editing (use system picker as-is)
- [ ] Not adding profile bio/status text fields (display name only)

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:
- **User-visible**: Profile update completes in <5 seconds, photo upload <3 seconds
- **System**: Real-time sync <100ms, image compression reduces file size by >50%
- **Quality**: 0 blocking bugs, all gates pass, crash-free >99%

---

## 5. Users & Stories

- As a **user**, I want to update my display name so that other users see my preferred name in conversations.
- As a **user**, I want to upload a profile photo so that I can personalize my identity in the app.
- As a **collaborator**, I want to see updated profile information in real-time so that I always see the latest user information.

---

## 6. Experience Specification (UX)

**Entry points and flows:**
- Accessible from Settings screen via "Edit Profile" button
- Navigation: Settings → Edit Profile → Save/Cancel

**Visual behavior:**
- Form with display name text field and profile photo picker
- Photo preview shows current/selected image
- Save button disabled until changes are made
- Loading spinner during image upload and save operations

**Loading/disabled/error states:**
- Loading: Spinner during upload/save operations
- Disabled: Save button disabled until valid changes
- Error: Alert for validation errors, network failures, upload failures

**Performance:** See targets in `Psst/agents/shared-standards.md`

---

## 7. Functional Requirements (Must/Should)

**MUST:**
- Display name validation (2-50 characters, no empty strings)
- PHPicker integration for photo selection from device library
- Firebase Storage upload with proper compression (max 1MB, JPEG format)
- Real-time profile updates across all screens (<100ms sync)
- Form validation with clear error messages
- Loading states during upload and save operations

**SHOULD:**
- Optimistic UI updates (show changes immediately, revert on error)
- Image compression to reduce file size while maintaining quality
- Cancel functionality to discard unsaved changes

**Acceptance gates per requirement:**
- [Gate] When user updates display name → All screens show new name in <100ms
- [Gate] When user uploads photo → Image appears in all screens in <100ms
- [Gate] Validation: Empty name shows error, invalid characters rejected
- [Gate] Upload: Large images compressed to <1MB, upload completes in <3 seconds
- [Gate] Error case: Network failure shows retry option, no partial updates

---

## 8. Data Model

**User Document Updates:**
```swift
{
  uid: String,
  displayName: String,        // Updated field
  email: String,
  profilePhotoURL: String,    // New field - Firebase Storage URL
  createdAt: Timestamp,
  updatedAt: Timestamp        // New field - track profile changes
}
```

**Validation rules:**
- displayName: required, 2-50 characters, no special characters
- profilePhotoURL: optional, valid Firebase Storage URL format
- updatedAt: automatically set to server timestamp on updates

**Indexing/queries:**
- No new composite indexes needed (existing user queries sufficient)
- Real-time listeners on user documents for profile updates

---

## 9. API / Service Contracts

**UserService Updates:**
```swift
// Update user profile information
func updateUserProfile(uid: String, displayName: String?, profilePhotoURL: String?) async throws

// Upload profile photo to Firebase Storage
func uploadProfilePhoto(uid: String, imageData: Data) async throws -> String

// Get current user profile
func getCurrentUserProfile() async throws -> User

// Listen for profile updates
func observeUserProfile(uid: String, completion: @escaping (User) -> Void) -> ListenerRegistration
```

**Pre/post-conditions:**
- updateUserProfile: User must be authenticated, displayName validated
- uploadProfilePhoto: Image must be <1MB, valid image format
- All methods: Proper error handling for network/auth failures

**Error handling strategy:**
- Network errors: Show retry option with user-friendly message
- Validation errors: Show specific field validation messages
- Upload errors: Show upload failure with retry option

---

## 10. UI Components to Create/Modify

**New Files:**
- `Views/Profile/EditProfileView.swift` — Main profile editing screen
- `Components/ProfilePhotoPicker.swift` — Photo selection component
- `Components/ProfilePhotoPreview.swift` — Photo preview with loading states

**Modified Files:**
- `Views/Profile/ProfileView.swift` — Add edit profile navigation
- `Services/UserService.swift` — Add profile update methods
- `Models/User.swift` — Add profilePhotoURL and updatedAt fields
- `Views/Components/PresenceIndicator.swift` — Update to show profile photos
- `Views/ChatList/ChatRowView.swift` — Display profile photos in chat list
- `Views/ChatList/ChatView.swift` — Display profile photos in chat header

---

## 11. Integration Points

- **Firebase Authentication**: Verify user identity for profile updates
- **Firebase Storage**: Upload and store profile photos with proper security rules
- **Firestore**: Update user documents with new profile information
- **Real-time listeners**: Sync profile changes across all app screens
- **PHPicker**: Native iOS photo selection from device library
- **State management**: SwiftUI @StateObject for form state and loading states

---

## 12. Testing Plan & Acceptance Gates

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

**Configuration Testing:**
- [ ] Firebase Authentication setup works
- [ ] Firebase Storage configured with proper security rules
- [ ] Firestore database connection established
- [ ] All environment variables and API keys properly set

**Happy Path Testing:**
- [ ] User can update display name successfully
- [ ] User can upload profile photo successfully
- [ ] Profile changes appear in all screens within 100ms
- [ ] Gate: Profile updates sync across 2+ devices in real-time

**Edge Cases Testing:**
- [ ] Empty display name shows validation error
- [ ] Display name >50 characters shows validation error
- [ ] Large image files are compressed appropriately
- [ ] Network failure during upload shows retry option
- [ ] Invalid image formats are rejected gracefully

**Multi-User Testing:**
- [ ] Profile changes visible to other users in <100ms
- [ ] Profile photos appear in chat list and conversation headers
- [ ] Concurrent profile updates handled correctly

**Performance Testing (see shared-standards.md):**
- [ ] Image upload completes in <3 seconds
- [ ] Profile sync across devices in <100ms
- [ ] App remains responsive during upload operations

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:
- [ ] UserService methods implemented with proper error handling
- [ ] SwiftUI views with all states (empty, loading, error, success)
- [ ] Real-time profile sync verified across 2+ devices
- [ ] Firebase Storage integration with proper security rules
- [ ] All acceptance gates pass
- [ ] Manual testing completed (configuration, user flows, multi-device, offline)
- [ ] Documentation updated

---

## 14. Risks & Mitigations

- **Risk**: Large image uploads slow down app → **Mitigation**: Implement compression, show progress indicators
- **Risk**: Profile sync conflicts with concurrent updates → **Mitigation**: Use Firestore server timestamps, handle conflicts gracefully
- **Risk**: Storage costs from large photos → **Mitigation**: Enforce 1MB limit, aggressive compression
- **Risk**: Network failures during upload → **Mitigation**: Retry mechanism, offline queue for profile updates

---

## 15. Rollout & Telemetry

- **Feature flag**: No (core profile functionality)
- **Metrics**: Profile update success rate, image upload time, sync latency
- **Manual validation steps**: Test profile updates across multiple devices

---

## 16. Open Questions

- Q1: Should we implement profile photo deletion or just replacement?
- Q2: What compression ratio should we target for profile photos?

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Profile photo cropping/editing tools
- [ ] Profile bio/status text fields
- [ ] Profile photo deletion functionality
- [ ] Video profile photos

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** User can update their display name and profile photo, with changes visible across all app screens.

2. **Primary user and critical action?** User updating their profile information to personalize their identity.

3. **Must-have vs nice-to-have?** Must-have: Display name editing, photo upload, real-time sync. Nice-to-have: Photo cropping, advanced validation.

4. **Real-time requirements?** Profile changes must sync across all devices in <100ms.

5. **Performance constraints?** Image upload <3 seconds, profile sync <100ms, app remains responsive.

6. **Error/edge cases to handle?** Network failures, invalid inputs, large images, concurrent updates.

7. **Data model changes?** Add profilePhotoURL and updatedAt fields to User model.

8. **Service APIs required?** UserService methods for profile updates, Firebase Storage integration.

9. **UI entry points and states?** Settings screen → Edit Profile → Form with validation and loading states.

10. **Security/permissions implications?** Firebase Storage security rules, photo library permissions.

11. **Dependencies or blocking integrations?** Requires PR #3 (user profiles) and PR #4 (navigation).

12. **Rollout strategy and metrics?** Direct deployment, track profile update success rates.

13. **What is explicitly out of scope?** Photo deletion, video uploads, profile bio fields, photo editing tools.

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `Psst/agents/shared-standards.md` throughout
