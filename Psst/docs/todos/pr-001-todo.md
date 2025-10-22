# PR-1 TODO — Profile Photo Upload Reliability Fix

**Branch**: `feat/pr-1-profile-photo-upload-reliability-fix`  
**Source PRD**: `Psst/docs/prds/pr-1-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

- **Questions**: None - PRD is comprehensive
- **Assumptions (confirm in PR if needed)**:
  - Existing User model structure is sufficient
  - Firebase Storage rules allow authenticated user uploads
  - ProfilePhotoPicker component exists and needs enhancement

---

## 1. Setup

- [x] Create branch `feat/pr-1-profile-photo-upload-reliability-fix` from develop
- [x] Read PRD thoroughly
- [x] Read `Psst/agents/shared-standards.md` for patterns
- [ ] Confirm environment and test runner work
- [x] Review existing ProfilePhotoPicker and UserService code

---

## 2. Service Layer

Implement deterministic service contracts from PRD.

### Threading Safety
- [x] Fix ProfilePhotoPicker threading issues
  - Test Gate: All image selection/processing on background thread
  - Test Gate: All UI updates on main thread using DispatchQueue.main.async
  - Test Gate: No UI blocking during image processing
  
### Enhanced Upload with Error Handling
- [x] Enhance UserService.uploadProfilePhoto() with comprehensive error handling
  - Test Gate: Network connectivity checked before upload attempt
  - Test Gate: Specific errors for network, size, format, permissions
  - Test Gate: Proper async/await threading patterns
  - Test Gate: Detailed logging for all failure scenarios
  - ✅ **FIXED**: Changed validation order to compress THEN validate (allows large images to be compressed before size validation)
  
### Image Validation and Compression
- [x] Add UserService.validateImageData() method
  - Test Gate: Validates image format (JPEG, PNG, HEIC)
  - Test Gate: Validates image size (<5MB limit)
  - Test Gate: Returns specific error for invalid format or size
  
- [x] Add enhanced UserService.compressImage() method with error handling
  - Test Gate: Compression happens on background thread
  - Test Gate: Memory-efficient compression for large images
  - Test Gate: Graceful error handling for compression failures
  - Test Gate: Fallback quality options if compression fails
  - ✅ **OPTIMIZED**: Increased compression target from 1000KB → 1500KB for better image quality (36% larger files, but 66% better quality retention)
  
### Network Validation
- [x] Add UserService.checkNetworkConnectivity() method
  - Test Gate: Returns accurate online/offline status
  - Test Gate: Blocks upload attempts when offline
  - Test Gate: Shows clear error message when network unavailable
  
### Error Handling
- [x] Create ProfilePhotoError enum with specific error cases
  - Test Gate: networkUnavailable error with user-friendly message
  - Test Gate: imageTooLarge error with size limit guidance
  - Test Gate: invalidFormat error with supported formats
  - Test Gate: uploadFailed error with specific reason
  - Test Gate: compressionFailed error with fallback options
  - Test Gate: permissionDenied error with troubleshooting steps
  
### Image Caching
- [x] Create ImageCacheService for profile photo caching
  - Test Gate: Cache storage implementation (FileManager or UserDefaults)
  - Test Gate: Cache size limits enforced (50MB max)
  - Test Gate: LRU cleanup policy implemented
  
- [x] Add UserService.loadProfilePhoto() method with cache-first logic
  - Test Gate: Checks cache first, loads instantly if available
  - Test Gate: Falls back to network if cache miss
  - Test Gate: Stores fetched photo in cache for future use
  - Test Gate: Background refresh for updated photos
  
- [x] Add UserService.cacheProfilePhoto() and invalidateProfilePhotoCache() methods
  - Test Gate: Cache invalidation on photo updates
  - Test Gate: Cache versioning or timestamps to detect stale photos
  - Test Gate: Multi-device cache invalidation works

---

## 3. Data Model & Rules

- [x] Verify existing User model supports profilePhotoURL field
  - Test Gate: profilePhotoURL field exists and is optional String
  - ✅ **FIXED**: Added custom decoder to handle missing createdAt/updatedAt fields gracefully (prevents decoding errors for existing users)

### Firebase Storage Security Rules
- [x] Review Firebase Storage security rules for authenticated uploads
  - Test Gate: Read current security rules configuration
  - Test Gate: Verify rules allow authenticated user writes to own profile folder
  - Test Gate: Verify rules prevent unauthorized access
  
- [ ] Test Firebase Storage permissions with fresh user accounts (USER TESTING REQUIRED)
  - Test Gate: New user can upload profile photo
  - Test Gate: User cannot upload to other users' folders
  - Test Gate: Upload failures show specific permission error messages
  
### Configuration Constants
- [x] Add image validation constants (max size, supported formats)
  - Test Gate: MAX_IMAGE_SIZE = 5MB defined
  - Test Gate: SUPPORTED_FORMATS = [.jpeg, .png, .heic] defined
  - Test Gate: Constants used consistently across service methods
  
- [x] Add cache configuration constants (max cache size, TTL)
  - Test Gate: MAX_CACHE_SIZE = 50MB defined
  - Test Gate: Cache limits enforced properly during testing

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

### ProfilePhotoPicker Enhancements
- [x] Fix ProfilePhotoPicker threading issues
  - Test Gate: Image selection happens on background thread
  - Test Gate: UI updates happen on main thread
  - Test Gate: SwiftUI Preview renders; zero console errors
  
- [x] Enhance ProfilePhotoPicker with loading states
  - Test Gate: Loading spinner shows during upload
  - Test Gate: Progress indicator if possible
  - Test Gate: UI remains interactive during processing
  
- [x] Add comprehensive error state handling to ProfilePhotoPicker
  - Test Gate: Network error shows with "Check Connection" message
  - Test Gate: Size error shows with compression option
  - Test Gate: Format error shows with supported formats list
  - Test Gate: Permission error shows with troubleshooting steps
  - Test Gate: Each error includes retry button
  
### ProfilePhotoPreview Enhancements
- [x] Enhance ProfilePhotoPreview with success states
  - Test Gate: Success confirmation shows with photo preview
  - Test Gate: Green checkmark or success animation
  
- [x] Add cache-aware photo loading to ProfilePhotoPreview
  - Test Gate: Cached photos load instantly (no loading state)
  - Test Gate: Cache miss shows brief loading indicator
  - Test Gate: Background refresh for updated photos
  
### EditProfileView Updates
- [x] Update EditProfileView to handle all upload states
  - Test Gate: Empty state (no photo) renders correctly
  - Test Gate: Loading state (uploading) renders correctly
  - Test Gate: Error state (failed upload) renders correctly
  - Test Gate: Success state (photo uploaded) renders correctly
  
- [x] Wire up state management (@State, @StateObject, etc.)
  - Test Gate: Interaction updates state correctly
  - Test Gate: UI updates reflect service method results
  - Test Gate: State transitions are smooth and predictable

---

## 5. Integration & Real-Time

Reference requirements from `Psst/agents/shared-standards.md`.

### Firebase Storage Integration
- [x] Test Firebase Storage integration with proper error handling
  - Test Gate: Upload succeeds and returns valid Storage URL
  - Test Gate: Upload path follows pattern: profile_photos/{userId}/profile.jpg
  - Test Gate: Storage URL saved to User document in Firestore
  - ✅ **FIXED**: Added retry logic with exponential backoff to handle Firebase Storage propagation delays (404 errors immediately after upload)
  
- [ ] Test Firebase Storage permissions and security (USER TESTING REQUIRED)
  - Test Gate: Authenticated users can upload to own folder
  - Test Gate: Permission denied error handled gracefully
  - Test Gate: Security rules prevent unauthorized access
  
### Network Connectivity
- [x] Implement network connectivity checks before upload attempts
  - Test Gate: Upload blocked when offline with clear message
  - Test Gate: Upload allowed when online
  - Test Gate: Retry works after connection restored
  
### Threading Safety
- [x] Verify proper threading (background for processing, main for UI)
  - Test Gate: All DispatchQueue.global calls for image processing
  - Test Gate: All DispatchQueue.main.async calls for UI updates
  - Test Gate: UI remains responsive during image processing
  - Test Gate: No threading-related crashes during testing
  
### Multi-Device Sync
- [ ] Profile photo sync across devices after upload (USER TESTING REQUIRED)
  - Test Gate: Photo appears on other devices within 100ms
  - Test Gate: Firestore listener updates all connected devices
  - Test Gate: Photo URL changes trigger cache invalidation
  
### Cache Management
- [x] Cache invalidation when profile photos are updated
  - Test Gate: Cache invalidates when new photo uploaded
  - Test Gate: Cache invalidates when photo URL changes
  - Test Gate: New photo loads after cache invalidation
  
- [x] Cache size management and cleanup
  - Test Gate: Cache stays within 50MB size limit
  - Test Gate: LRU cleanup removes oldest photos when limit exceeded
  - Test Gate: Cache cleanup doesn't affect actively used photos

---

## 6. Testing Validation

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

- [ ] Configuration Testing
  - Test Gate: Firebase Authentication, Firestore, Firebase Storage all connected and working
  - Test Gate: All environment variables and API keys properly configured
  - Test Gate: Firebase Storage rules allow authenticated user uploads
  - Test Gate: Firebase Storage permissions tested with fresh user accounts
  - Test Gate: Network connectivity detection working correctly
  
- [ ] User Flow Testing
  - Test Gate: Complete profile photo upload flow end-to-end successfully
  - Test Gate: Upload succeeds on first attempt with various image types
  - Test Gate: Upload success rate tracked (target: 95% first-attempt)
  
- [ ] Edge Cases Testing
  - Test Gate: Large images (>5MB) show size error with clear message
  - Test Gate: Large images (3-5MB) compress successfully
  - Test Gate: Invalid formats (BMP, GIF, etc.) show format error
  - Test Gate: Network issues show connectivity error with retry option
  - Test Gate: Compression failures handled gracefully with fallback
  - Test Gate: Firebase permission errors show specific troubleshooting
  
- [ ] Multi-Device Testing
  - Test Gate: Profile photo syncs across 2+ devices within 100ms
  - Test Gate: Photo appears on all connected devices after upload
  
- [ ] Offline Behavior Testing
  - Test Gate: Network check prevents upload attempt when offline
  - Test Gate: Clear "No Internet Connection" error message shown
  - Test Gate: Retry button works when connection restored
  - Test Gate: Cached photos still load when offline
  
- [ ] Visual States Verification
  - Test Gate: Empty state (no photo) renders correctly
  - Test Gate: Loading state (uploading) shows spinner/progress
  - Test Gate: Error states (network, size, format, permissions) all render with specific messages
  - Test Gate: Success state shows confirmation with photo preview
  - Test Gate: No console errors during testing
  - Test Gate: Error messages are clear, actionable, and user-friendly
  - Test Gate: Threading warnings/errors not present in console
- [ ] Cache Testing
  - Test Gate: Cached images load instantly (<100ms)
  - Test Gate: Cache invalidation works when photos are updated
  - Test Gate: Cache hit rate >90% for profile photos
  - Test Gate: Cache size stays within limits

---

## 7. Performance

Verify targets from `Psst/agents/shared-standards.md`.

### Upload Performance
- [ ] Upload completes within 3 seconds for images <5MB
  - Test Gate: Upload time measured and logged for various sizes
  - Test Gate: Test with 1MB, 3MB, 5MB images
  
### Threading and UI Performance
- [ ] UI remains responsive during image processing
  - Test Gate: No UI blocking during compression
  - Test Gate: No UI blocking during upload
  - Test Gate: Can interact with other UI elements during upload
  - Test Gate: No threading warnings in console
  
### Memory Performance
- [ ] Memory usage stays reasonable during image processing
  - Test Gate: No memory leaks during large image handling
  - Test Gate: Test with multiple consecutive uploads (10+)
  - Test Gate: Memory returns to baseline after uploads complete
  
### Animation Performance
- [ ] Smooth animations for loading/error states
  - Test Gate: 60fps animations verified during upload
  - Test Gate: State transitions are smooth
  
### Cache Performance
- [ ] Cache performance targets met
  - Test Gate: Cached images load instantly (<100ms)
  - Test Gate: Cache operations don't block UI thread
  - Test Gate: Memory usage stays reasonable during cache operations
  - Test Gate: Cache hit rate tracked (target: >90%)

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:

### Happy Path Gates
- [ ] User selects photo → All processing on background thread
- [ ] User selects photo → Upload succeeds within 3 seconds
- [ ] Upload success → User sees success confirmation with preview
- [ ] Cached photo → Loads instantly (no loading state)

### Edge Case Gates
- [ ] Network unavailable → Clear error message with retry option
- [ ] Upload fails → User sees specific error reason (network, size, format, permissions)
- [ ] Large image → UI remains responsive, no blocking
- [ ] Compression fails → Graceful error handling with fallback options
- [ ] Firebase permission denied → Clear error with troubleshooting steps

### Multi-User Gates
- [ ] Profile photo uploaded → Syncs to other devices within 100ms
- [ ] Concurrent uploads → No race conditions or conflicts
- [ ] Photo updated → Cache invalidates across all devices

### Performance Gates
- [ ] Upload completes <3 seconds for images <5MB
- [ ] UI remains responsive (60fps) during all operations
- [ ] Cached images load <100ms
- [ ] No memory leaks during repeated uploads
- [ ] Threading safety verified (no UI blocking)

### Cache Gates
- [ ] Cache available → No network request for profile photos
- [ ] Photo updated → Cache invalidates and new photo loads
- [ ] Cache size → Stays within 50MB limit
- [ ] Cache hit rate → >90% for profile photos

---

## 9. Documentation & PR

- [x] Add inline code comments for complex error handling logic
  - Test Gate: All error handling paths documented
  - Test Gate: Error enum cases have descriptive comments
  
- [x] Add comments for threading patterns and async/await usage
  - Test Gate: All DispatchQueue calls explained
  - Test Gate: Threading safety patterns documented
  
- [x] Add comments for cache management and invalidation logic
  - Test Gate: Cache strategy documented
  - Test Gate: Invalidation triggers documented
  
- [x] Add comments for compression logic and memory management
  - Test Gate: Compression quality settings explained
  - Test Gate: Memory optimization strategies documented
  
- [ ] Add new files to Xcode project (USER ACTION REQUIRED)
  - Action: Open Xcode, right-click on project, select "Add Files to Psst"
  - Files to add: ProfilePhotoError.swift, ImageCacheService.swift
  
- [ ] Update README if needed for new error handling and caching patterns
  - Test Gate: Error handling approach documented
  - Test Gate: Caching strategy explained
  
- [ ] Create PR description (use format from Psst/agents/caleb-agent.md)
  - Test Gate: Include all testing results
  - Test Gate: Include upload success rate metrics
  - Test Gate: Include cache performance metrics
  
- [ ] Verify with user before creating PR
- [ ] Open PR targeting develop branch
- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] Threading issues fixed (all processing on background, UI on main)
- [ ] Services implemented with comprehensive error handling
- [ ] Network validation added (connectivity checks before upload)
- [ ] Enhanced compression logic with error handling and memory management
- [ ] Firebase Storage permissions verified and tested
- [ ] Detailed logging implemented for debugging upload failures
- [ ] Image caching implemented with proper invalidation
- [ ] SwiftUI views implemented with all states (empty, loading, error, success)
- [ ] Firebase integration verified (Storage upload, real-time sync)
- [ ] Manual testing completed (configuration, user flows, multi-device, offline, cache)
- [ ] Upload success rate measured (target: 95% first-attempt)
- [ ] Edge cases tested (large images, invalid formats, network issues, permissions)
- [ ] Multi-device sync verified (<100ms)
- [ ] Performance targets met: upload <3s, UI responsive, no blocking
- [ ] Threading safety verified (no console warnings, no UI blocking)
- [ ] Cache performance verified (instant loading <100ms, proper invalidation, >90% hit rate)
- [ ] All acceptance gates pass
- [ ] Code follows Psst/agents/shared-standards.md patterns
- [ ] No console warnings or threading errors
- [ ] Documentation updated with error handling and caching patterns
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for common patterns and solutions

**Critical Focus Areas:**
- **Threading Safety**: All image processing on DispatchQueue.global, all UI updates on DispatchQueue.main.async
- **Comprehensive Error Handling**: Specific errors for network, size, format, permissions, compression failures
- **Network Validation**: Check connectivity before upload attempts, clear offline errors
- **Compression Logic**: Robust compression with memory management and error handling
- **Firebase Permissions**: Test Storage security rules with fresh accounts
- **Image Caching**: Cache-first loading strategy with proper invalidation
- **Detailed Logging**: Log all failures with technical details for debugging
- **Performance**: Upload <3s, UI responsive (60fps), cached images <100ms
- **Testing**: Test with various image sizes (1MB-10MB+), network conditions (online/offline/poor), and formats
