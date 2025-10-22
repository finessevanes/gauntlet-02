# PRD: Profile Photo Upload Reliability Fix

**Feature**: profile-photo-upload-reliability-fix

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Caleb

**Target Release**: Phase 1 (MVP Polish)

**Links**: [PR Brief], [TODO], [Designs], [Tracking Issue]

---

## 1. Summary

Fix critical user experience issues with profile photo handling: (1) New users unable to upload profile photos on first attempt, requiring multiple retries, and (2) Profile photos load every time the app opens instead of being cached, creating jarring loading experiences. This affects all users and occurs with both native camera photos and real fence images, creating a frustrating experience that could lead to user abandonment.

---

## 2. Problem & Goals

**User Problem**: 
1. **Upload Failures**: New users cannot upload profile photos on first attempt, requiring multiple retries due to:
   - Threading problems in ProfilePhotoPicker (UI blocking, async/await issues)
   - Compression logic failures (crashes, memory issues with large images)
   - Insufficient error handling (generic errors, no retry guidance)
   - Potential Firebase Storage permission issues
   - Lack of network state validation before upload attempts

2. **Caching Issues**: Profile photos load every time the app opens instead of being cached, creating jarring loading experiences. Photos should load instantly from cache with background refresh for updates.

**Why Now**: These are critical UX issues affecting all users and blocking successful app adoption. The upload failures prevent profile completion, and the caching issues create poor perceived performance.

**Goals (ordered, measurable):**
- [ ] G1 — 95% of profile photo uploads succeed on first attempt (vs current ~60%)
- [ ] G2 — Upload failures show clear, actionable error messages to users
- [ ] G3 — Upload process completes within 3 seconds for images <5MB
- [ ] G4 — Profile photos load instantly from cache when available (no loading states for cached images)
- [ ] G5 — Cache invalidation works properly when photos are updated with background refresh
- [ ] G6 — All image processing happens on background threads (no UI blocking)

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing video upload support (images only)
- [ ] Not changing existing compression algorithms (only improving error handling)
- [ ] Not implementing batch photo uploads (single photo per user)
- [ ] Not adding photo editing features (crop, filters, etc.)
- [ ] Not implementing advanced cache management (basic caching only)

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:
- **User-visible**: 95% first-attempt success rate, <3s upload time, clear error messages, instant cache loading
- **System**: Upload latency <3s, zero threading-related crashes, proper error logging, cache hit rate >90%
- **Quality**: 0 blocking bugs, all gates pass, crash-free >99%

---

## 5. Users & Stories

- As a new user, I want to upload my profile photo on the first try so that I can complete my profile setup quickly.
- As a user with poor network, I want clear feedback when uploads fail so that I know what to do next.
- As a user, I want upload progress indicators so that I know the system is working.
- As a user, I want profile photos to load instantly from cache so that I don't see loading states for photos I've already viewed.
- As a user, I want updated profile photos to refresh automatically so that I always see the latest version.

---

## 6. Experience Specification (UX)

**Entry points and flows**: Profile setup flow, Edit Profile screen
**Visual behavior**: 
- Progress indicator during upload
- Success confirmation with photo preview
- Clear error messages with retry options
- Loading states that don't block UI

**Loading/disabled/error states**: 
- Loading: Spinner with "Uploading..." text
- Error: Red alert with specific error message and "Try Again" button
- Success: Green checkmark with photo preview
- Cache loading: Instant display from cache (no loading state)
- Cache miss: Brief loading indicator while fetching from network

**Performance**: See targets in `Psst/agents/shared-standards.md` (upload <3s, no UI blocking)

---

## 7. Functional Requirements (Must/Should)

**MUST**: 
- **Threading Safety**: All image processing on background threads, UI updates on main thread
- **Compression Logic**: Enhanced compression with proper error handling, memory management
- **Error Handling**: Comprehensive error handling with user-friendly error messages
- **Network Validation**: Check network connectivity before upload attempts
- **Retry Mechanisms**: Allow users to retry failed uploads with clear guidance
- **Detailed Logging**: Log all upload failures with technical details for debugging
- **Image Caching**: Implement local image caching with proper cache invalidation
- **Instant Loading**: Profile photos load instantly from cache when available
- **Background Refresh**: Updated photos refresh in background without blocking UI
- **Upload Success Rate**: 95% first-attempt success rate
- **Firebase Storage Permissions**: Verify and test storage security rules

**SHOULD**: 
- Progress indicators during upload
- Optimistic UI updates
- Automatic retry for transient failures
- Cache size management and cleanup
- Offline cache access

**Acceptance gates per requirement:**
- [Gate] When user selects photo → All processing happens on background thread
- [Gate] When user selects photo → Upload succeeds within 3 seconds
- [Gate] When network is unavailable → Clear error message with retry option  
- [Gate] When upload fails → User sees specific error reason (network, size, format, permissions) and can retry
- [Gate] When processing large image → UI remains responsive, no blocking
- [Gate] When compression fails → Graceful error handling with fallback options
- [Gate] When viewing cached profile photo → Photo loads instantly (no loading state)
- [Gate] When profile photo is updated → Cache invalidates and new photo loads
- [Gate] When cache is available → No network request for profile photos
- [Gate] When Firebase Storage permission denied → Clear error message with troubleshooting steps

---

## 8. Data Model

No changes to existing User model. Current structure:
```swift
struct User {
    let id: String
    let email: String
    let displayName: String
    let profilePhotoURL: String?  // Firebase Storage URL
    let createdAt: Date
    let lastSeen: Date
}
```

**Validation rules**: 
- Profile photo URL must be valid Firebase Storage URL
- Image size limit: 5MB
- Supported formats: JPEG, PNG, HEIC

**Indexing/queries**: No new indexes needed (existing user queries work)

---

## 9. API / Service Contracts

Specify concrete service layer methods:

```swift
// Enhanced UserService methods
func uploadProfilePhoto(imageData: Data, userID: String) async throws -> String
func validateImageData(_ data: Data) throws -> Bool
func compressImage(_ image: UIImage, maxSizeKB: Int = 500) async throws -> Data
func checkNetworkConnectivity() async -> Bool

// Image caching methods
func loadProfilePhoto(userID: String) async throws -> UIImage
func cacheProfilePhoto(_ image: UIImage, userID: String) async
func invalidateProfilePhotoCache(userID: String) async
func getCachedProfilePhoto(userID: String) async -> UIImage?

// Error handling
enum ProfilePhotoError: Error {
    case networkUnavailable
    case imageTooLarge
    case invalidFormat
    case uploadFailed(String)
    case compressionFailed
    case cacheError(String)
}
```

**Pre/post-conditions for each method:**
- `uploadProfilePhoto`: Pre: valid image data, user authenticated; Post: returns Firebase Storage URL
- `validateImageData`: Pre: non-empty data; Post: returns true if valid format and size
- `compressImage`: Pre: valid UIImage; Post: returns compressed Data < maxSizeKB
- `loadProfilePhoto`: Pre: valid userID; Post: returns UIImage from cache or network
- `cacheProfilePhoto`: Pre: valid UIImage and userID; Post: image stored in cache
- `invalidateProfilePhotoCache`: Pre: valid userID; Post: cache entry removed
- `getCachedProfilePhoto`: Pre: valid userID; Post: returns UIImage if cached, nil otherwise

**Error handling strategy**: Throw specific errors with user-friendly messages, log technical details

---

## 10. UI Components to Create/Modify

- `Views/Profile/EditProfileView.swift` — Add upload progress and error states
- `Components/ProfilePhotoPicker.swift` — Enhance with better error handling
- `Components/ProfilePhotoPreview.swift` — Add loading and error states
- `Services/UserService.swift` — Add enhanced upload methods with error handling
- `Services/ImageCacheService.swift` — New service for image caching
- `Utilities/ImageCompression.swift` — New utility for image processing

---

## 11. Integration Points

- Firebase Authentication (user verification)
- Firebase Storage (photo upload)
- Network monitoring (connectivity checks)
- State management (SwiftUI patterns for loading/error states)
- Local file system (image caching)
- Cache management (invalidation, size limits)

---

## 12. Testing Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

**Configuration Testing**
- [ ] Firebase Storage rules allow authenticated user uploads
- [ ] Firebase Authentication working for user verification
- [ ] Network connectivity detection working
- [ ] All environment variables and API keys properly set

**Happy Path Testing**
- [ ] User selects photo → Upload succeeds within 3 seconds
- [ ] User sees success confirmation with photo preview
- [ ] Photo appears in profile immediately

**Edge Cases Testing**
- [ ] Large image (>5MB) shows size error with compression option
- [ ] Invalid image format shows format error
- [ ] Network unavailable shows connectivity error with retry
- [ ] Upload timeout shows timeout error with retry
- [ ] Firebase permission denied shows permission error

**Multi-User Testing**
- [ ] Multiple users can upload photos simultaneously
- [ ] Profile photos sync across devices after upload
- [ ] No race conditions with concurrent uploads

**Performance Testing (see shared-standards.md)**
- [ ] Upload completes < 3 seconds for images <5MB
- [ ] UI remains responsive during upload processing
- [ ] No memory leaks during image compression
- [ ] Smooth animations for loading/error states
- [ ] Cached images load instantly (<100ms)
- [ ] Cache hit rate >90% for profile photos
- [ ] Cache size stays within reasonable limits

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:
- [ ] Service methods implemented with proper error handling
- [ ] SwiftUI views with all states (empty, loading, error, success)
- [ ] Real-time sync verified across 2+ devices
- [ ] Offline persistence tested manually
- [ ] All acceptance gates pass
- [ ] Manual testing completed (configuration, user flows, multi-device, offline)
- [ ] Docs updated

---

## 14. Risks & Mitigations

- **Risk**: Threading issues cause crashes or UI blocking → **Mitigation**: 
  - Use DispatchQueue.global for image processing
  - Use DispatchQueue.main.async for all UI updates
  - Test with various image sizes to verify no blocking
  - Add threading safety assertions
  
- **Risk**: Large images cause memory issues or compression failures → **Mitigation**: 
  - Implement robust compression with error handling
  - Test with 10MB+ images from various sources
  - Add memory usage monitoring
  - Implement compression quality fallback options
  
- **Risk**: Network timeouts not handled → **Mitigation**: 
  - Add network connectivity checks before upload
  - Implement timeout detection with clear error messages
  - Add retry logic with exponential backoff
  - Test with poor network conditions
  
- **Risk**: Firebase Storage permissions issues prevent uploads → **Mitigation**: 
  - Review and test Firebase Storage security rules
  - Test with fresh user accounts
  - Add specific permission error messages
  - Verify authenticated user can write to own profile folder
  
- **Risk**: Cache grows too large and impacts performance → **Mitigation**: 
  - Implement cache size limits (e.g., 50MB max)
  - Add LRU cleanup policies
  - Monitor cache size during testing
  
- **Risk**: Cache invalidation fails causing stale photos → **Mitigation**: 
  - Test cache invalidation on photo updates
  - Implement background refresh mechanism
  - Add cache versioning or timestamps
  - Test with multiple devices updating same profile

---

## 15. Rollout & Telemetry

- **Feature flag?** No (critical bug fix)
- **Metrics**: Upload success rate, upload time, error frequency by type, cache hit rate, cache size
- **Manual validation steps**: Test with various image sizes, network conditions, user accounts, and cache scenarios

---

## 16. Open Questions

- Q1: Should we implement automatic image compression for oversized images?
- Q2: What's the maximum acceptable upload time before showing timeout error?
- Q3: What's the optimal cache size limit for profile photos?
- Q4: Should we implement cache warming on app launch?

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Video profile photos
- [ ] Photo editing features (crop, filters)
- [ ] Batch photo uploads
- [ ] Photo backup/sync across devices
- [ ] Advanced cache management (LRU, TTL)
- [ ] Cache warming strategies

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** User successfully uploads profile photo on first attempt and sees cached photos load instantly
2. **Primary user and critical action?** New user uploading profile photo during onboarding, existing user viewing cached photos
3. **Must-have vs nice-to-have?** Must: reliable upload, clear errors, instant cache loading. Nice: progress indicators, cache warming
4. **Real-time requirements?** Profile photo should sync to other devices after upload, cache should invalidate on updates
5. **Performance constraints?** Upload <3s, no UI blocking, smooth animations, cached images <100ms
6. **Error/edge cases to handle?** Network issues, large images, invalid formats, timeouts, cache failures
7. **Data model changes?** None (existing User model sufficient)
8. **Service APIs required?** Enhanced UserService.uploadProfilePhoto with error handling, new ImageCacheService
9. **UI entry points and states?** EditProfileView, ProfilePhotoPicker with loading/error states, cached photo display
10. **Security/permissions implications?** Verify Firebase Storage rules allow authenticated uploads, secure cache storage
11. **Dependencies or blocking integrations?** Depends on PR #17 (user profile editing)
12. **Rollout strategy and metrics?** Direct deployment, monitor upload success rates and cache performance
13. **What is explicitly out of scope?** Video uploads, photo editing, batch uploads, advanced cache management

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `Psst/agents/shared-standards.md` throughout
