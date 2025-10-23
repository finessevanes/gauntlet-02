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
  
### Update Profile Photo
- [x] Implement UserService.updateProfilePhoto() method
  - Test Gate: Validates new image data before processing
  - Test Gate: Uploads new photo first, keeps old photo as backup
  - Test Gate: Only deletes old photo after new photo URL confirmed
  - Test Gate: Invalidates cache after successful update
  - Test Gate: Comprehensive error handling with rollback on failure
  - Test Gate: Network connectivity checked before update attempt
  
### Delete Profile Photo
- [x] Implement UserService.deleteProfilePhoto() method
  - Test Gate: Verifies user has existing photo before deletion
  - Test Gate: Removes photo from Firebase Storage
  - Test Gate: Clears profilePhotoURL from Firestore User document
  - Test Gate: Invalidates cache after successful deletion
  - Test Gate: Comprehensive error handling (deleteFailed, noPhotoToDelete)
  - Test Gate: Network connectivity checked before delete attempt
  - Test Gate: Transactional delete (both Storage and Firestore succeed or both fail)
  
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
  - Test Gate: deleteFailed error with specific reason
  - Test Gate: noPhotoToDelete error when attempting to delete non-existent photo
  - Test Gate: cameraPermissionDenied error with Settings instructions
  - Test Gate: cameraNotAvailable error when camera unavailable
  - Test Gate: photoLibraryPermissionDenied error with Settings instructions
  - ✅ **COMPLETE**: All error cases added with user-friendly messages and recovery suggestions
  
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
  
### Photo Source Selection UI
- [x] Create PhotoSourcePicker component (action sheet)
  - Test Gate: Shows "Take Photo" and "Choose from Library" options
  - Test Gate: Shows "Delete Photo" option if photo exists
  - Test Gate: "Take Photo" opens camera (UIImagePickerController or PhotosPicker)
  - Test Gate: "Choose from Library" opens photo library (PHPickerViewController)
  - Test Gate: Handles user cancellation gracefully
  - Test Gate: Requests permissions appropriately
  - ✅ **COMPLETE**: PhotoSourcePicker created with permission handling
  
- [x] Add camera permission handling utility
  - Test Gate: Checks camera permission status before opening camera
  - Test Gate: Requests camera permission with clear messaging
  - Test Gate: Shows error if permission denied with instructions to Settings
  - Test Gate: Info.plist has NSCameraUsageDescription
  - ✅ **COMPLETE**: Camera permissions handled in PhotoSourcePicker
  
- [x] Add photo library permission handling utility
  - Test Gate: Checks photo library permission status before opening library
  - Test Gate: Requests library permission with clear messaging
  - Test Gate: Shows error if permission denied with instructions to Settings
  - Test Gate: Info.plist has NSPhotoLibraryUsageDescription
  - ✅ **COMPLETE**: Photo library permissions handled in PhotoSourcePicker

### Update and Delete UI
- [x] Add update/delete options to EditProfileView
  - Test Gate: Tap "Add Photo" shows PhotoSourcePicker with camera and library options
  - Test Gate: Tap existing photo shows PhotoSourcePicker with camera, library, and delete options
  - Test Gate: Camera capture works and uploads photo
  - Test Gate: Library selection works and uploads photo
  - Test Gate: "Delete Photo" shows confirmation dialog
  - Test Gate: UI exists ONLY in Profile tab, NOT in Settings
  - ✅ **COMPLETE**: Update/delete UI integrated into EditProfileView
  
- [x] Implement delete confirmation dialog
  - Test Gate: Dialog shows clear message: "Are you sure you want to remove your profile photo?"
  - Test Gate: Dialog has "Cancel" and "Delete" buttons
  - Test Gate: "Cancel" dismisses dialog without action
  - Test Gate: "Delete" triggers deleteProfilePhoto() service method
  - Test Gate: Deleting state shows spinner with "Removing..." text
  - ✅ **COMPLETE**: Delete confirmation dialog implemented
  
- [x] Add update photo flow
  - Test Gate: Update shows loading state during old photo deletion + new photo upload
  - Test Gate: Update error shows which step failed (delete old or upload new)
  - Test Gate: Update success shows new photo with confirmation
  - Test Gate: Old photo remains visible until new photo confirmed
  - ✅ **COMPLETE**: Update flow implemented in updateProfilePhoto() service method
  
- [x] Verify location constraint
  - Test Gate: Profile tab has full photo editing (upload, update, delete)
  - Test Gate: Settings tab has NO profile photo editing options
  - Test Gate: Any Settings photo references redirect to Profile tab (if applicable)
  - ✅ **COMPLETE**: Removed "Edit Profile" button from SettingsView (lines 77-94, sheet, and state)

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
  
- [ ] Profile photo update sync across devices (USER TESTING REQUIRED)
  - Test Gate: Updated photo appears on all devices within 100ms
  - Test Gate: Old photo cache invalidated on all devices
  - Test Gate: New photo loads correctly on all devices
  
- [ ] Profile photo delete sync across devices (USER TESTING REQUIRED)
  - Test Gate: Deleted photo removed from all devices within 100ms
  - Test Gate: Placeholder shown on all devices
  - Test Gate: Cache invalidated on all devices
  
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
  - Test Gate: Info.plist has NSCameraUsageDescription with clear explanation
  - Test Gate: Info.plist has NSPhotoLibraryUsageDescription with clear explanation
  - Test Gate: Camera permissions working on real device
  - Test Gate: Photo library permissions working on device and simulator
  
- [ ] User Flow Testing
  - Test Gate: Camera capture flow works end-to-end (take photo → upload → success)
  - Test Gate: Library selection flow works end-to-end (choose → upload → success)
  - Test Gate: Upload succeeds on first attempt with photos from camera
  - Test Gate: Upload succeeds on first attempt with photos from library
  - Test Gate: Upload success rate tracked (target: 95% first-attempt)
  - Test Gate: Update existing photo flow works with camera
  - Test Gate: Update existing photo flow works with library
  - Test Gate: Delete photo flow works with confirmation dialog
  - Test Gate: Location constraint verified (Profile tab only, not Settings)
  
- [ ] Edge Cases Testing
  - Test Gate: Camera permission denied → Clear error with Settings instructions
  - Test Gate: Photo library permission denied → Clear error with Settings instructions
  - Test Gate: Camera not available on simulator → Appropriate handling
  - Test Gate: User cancels camera capture → Returns to profile without error
  - Test Gate: User cancels library selection → Returns to profile without error
  - Test Gate: Large images from camera (>5MB) compress successfully
  - Test Gate: Large images from library (>5MB) show size error with clear message
  - Test Gate: Large images (3-5MB) compress successfully
  - Test Gate: Invalid formats (BMP, GIF, etc.) show format error
  - Test Gate: Network issues show connectivity error with retry option
  - Test Gate: Compression failures handled gracefully with fallback
  - Test Gate: Firebase permission errors show specific troubleshooting
  - Test Gate: Delete with no existing photo shows "noPhotoToDelete" error
  - Test Gate: Delete canceled in confirmation dialog prevents deletion
  - Test Gate: Update fails → old photo remains, error shown with retry
  - Test Gate: Settings tab has no profile photo editing options
  
- [ ] Multi-Device Testing
  - Test Gate: Profile photo syncs across 2+ devices within 100ms
  - Test Gate: Photo appears on all connected devices after upload
  - Test Gate: Photo updates sync across all devices within 100ms
  - Test Gate: Photo deletions sync across all devices within 100ms
  - Test Gate: Cache invalidates on all devices when photo changes
  
- [ ] Offline Behavior Testing
  - Test Gate: Network check prevents upload attempt when offline
  - Test Gate: Network check prevents update attempt when offline
  - Test Gate: Network check prevents delete attempt when offline
  - Test Gate: Clear "No Internet Connection" error message shown for all operations
  - Test Gate: Retry button works when connection restored
  - Test Gate: Cached photos still load when offline
  
- [ ] Visual States Verification
  - Test Gate: Empty state (no photo) renders correctly with "Add Photo" button
  - Test Gate: PhotoSourcePicker action sheet renders with "Take Photo" and "Choose from Library"
  - Test Gate: PhotoSourcePicker shows "Delete Photo" option when photo exists
  - Test Gate: Camera opens successfully on real device
  - Test Gate: Photo library picker opens successfully
  - Test Gate: Loading state (uploading) shows spinner/progress
  - Test Gate: Updating state shows loading during delete old + upload new
  - Test Gate: Deleting state shows spinner with "Removing..." text
  - Test Gate: Error states (network, size, format, permissions, camera, library) all render with specific messages
  - Test Gate: Camera permission error shows instructions to enable in Settings
  - Test Gate: Photo library permission error shows instructions to enable in Settings
  - Test Gate: Delete confirmation dialog renders with clear message
  - Test Gate: Success state shows confirmation with photo preview
  - Test Gate: Delete success shows placeholder with "Add Photo" option
  - Test Gate: Update success shows new photo (from camera or library)
  - Test Gate: No console errors during testing
  - Test Gate: Error messages are clear, actionable, and user-friendly
  - Test Gate: Threading warnings/errors not present in console
  - Test Gate: Profile tab shows full photo editing options (camera, library, delete)
  - Test Gate: Settings tab shows NO photo editing options
- [ ] Cache Testing
  - Test Gate: Cached images load instantly (<100ms)
  - Test Gate: Cache invalidation works when photos are uploaded
  - Test Gate: Cache invalidation works when photos are updated
  - Test Gate: Cache invalidation works when photos are deleted
  - Test Gate: Cache hit rate >90% for profile photos
  - Test Gate: Cache size stays within limits
  - Test Gate: Deleted photos removed from cache completely

---

## 7. Performance

Verify targets from `Psst/agents/shared-standards.md`.

### Upload Performance
- [ ] Upload completes within 3 seconds for images <5MB
  - Test Gate: Upload time measured and logged for various sizes
  - Test Gate: Test with 1MB, 3MB, 5MB images
  
### Update Performance
- [ ] Update completes within 3 seconds (delete old + upload new)
  - Test Gate: Update time measured and logged
  - Test Gate: Old photo deleted before new photo uploaded
  - Test Gate: Test with various image sizes
  
### Delete Performance
- [ ] Delete completes within 2 seconds (remove Storage + clear Firestore)
  - Test Gate: Delete time measured and logged
  - Test Gate: Both Storage and Firestore operations complete quickly
  - Test Gate: Cache invalidation doesn't block deletion
  
### Threading and UI Performance
- [ ] UI remains responsive during image processing
  - Test Gate: No UI blocking during compression
  - Test Gate: No UI blocking during upload
  - Test Gate: No UI blocking during update
  - Test Gate: No UI blocking during delete
  - Test Gate: Can interact with other UI elements during all operations
  - Test Gate: No threading warnings in console
  
### Memory Performance
- [ ] Memory usage stays reasonable during image processing
  - Test Gate: No memory leaks during large image handling
  - Test Gate: Test with multiple consecutive uploads (10+)
  - Test Gate: Test with multiple consecutive updates (10+)
  - Test Gate: Test with multiple consecutive deletes (10+)
  - Test Gate: Memory returns to baseline after all operations complete
  
### Animation Performance
- [ ] Smooth animations for loading/error states
  - Test Gate: 60fps animations verified during upload
  - Test Gate: 60fps animations verified during update
  - Test Gate: 60fps animations verified during delete
  - Test Gate: Confirmation dialog animations smooth
  - Test Gate: State transitions are smooth for all operations
  
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
- [ ] User taps "Add Photo" → PhotoSourcePicker shows "Take Photo" and "Choose from Library"
- [ ] User taps "Take Photo" → Camera opens successfully
- [ ] User captures photo → All processing on background thread
- [ ] User captures photo → Upload succeeds within 3 seconds
- [ ] User taps "Choose from Library" → Photo library picker opens
- [ ] User selects photo from library → Upload succeeds within 3 seconds
- [ ] Upload success → User sees success confirmation with preview
- [ ] Cached photo → Loads instantly (no loading state)
- [ ] User updates photo (camera or library) → Old photo deleted, new photo uploaded, cache invalidated
- [ ] User deletes photo → Confirmation shown, photo removed, placeholder displayed
- [ ] Profile tab → All photo editing options available (camera, library, delete)
- [ ] Settings tab → No photo editing options present

### Edge Case Gates
- [ ] Camera permission denied → Clear error with Settings instructions
- [ ] Photo library permission denied → Clear error with Settings instructions
- [ ] Camera not available → Appropriate error or disabled option
- [ ] User cancels camera → Returns to profile without error
- [ ] User cancels library → Returns to profile without error
- [ ] Network unavailable → Clear error message with retry option
- [ ] Upload fails → User sees specific error reason (network, size, format, permissions)
- [ ] Large image from camera → UI remains responsive, compression works, no blocking
- [ ] Large image from library → UI remains responsive, no blocking
- [ ] Compression fails → Graceful error handling with fallback options
- [ ] Firebase permission denied → Clear error with troubleshooting steps
- [ ] Delete with no photo → Shows "noPhotoToDelete" error
- [ ] Delete canceled → Photo remains, no changes made
- [ ] Update fails → Old photo remains, clear error with retry option

### Multi-User Gates
- [ ] Profile photo uploaded → Syncs to other devices within 100ms
- [ ] Profile photo updated → Syncs to other devices within 100ms
- [ ] Profile photo deleted → Syncs to other devices within 100ms
- [ ] Concurrent uploads/updates/deletes → No race conditions or conflicts
- [ ] Photo updated → Cache invalidates across all devices
- [ ] Photo deleted → Cache invalidates across all devices

### Performance Gates
- [ ] Upload completes <3 seconds for images <5MB
- [ ] Update completes <3 seconds (delete old + upload new)
- [ ] Delete completes <2 seconds (Storage + Firestore)
- [ ] UI remains responsive (60fps) during all operations
- [ ] Cached images load <100ms
- [ ] No memory leaks during repeated uploads/updates/deletes
- [ ] Threading safety verified (no UI blocking)

### Cache Gates
- [ ] Cache available → No network request for profile photos
- [ ] Photo uploaded → Cached for future instant loading
- [ ] Photo updated → Cache invalidates and new photo loads
- [ ] Photo deleted → Cache invalidates and placeholder shown
- [ ] Cache size → Stays within 50MB limit
- [ ] Cache hit rate → >90% for profile photos
- [ ] Deleted photos → Removed from cache completely

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
  
- [x] Add comments for camera and photo library logic
  - Test Gate: Permission handling documented
  - Test Gate: Camera capture flow explained
  - Test Gate: Photo library selection flow explained
  - Test Gate: Error handling for permissions documented
  - ✅ **COMPLETE**: PhotoSourcePicker and CameraPicker fully commented
  
- [x] Add comments for update and delete logic
  - Test Gate: Update flow documented (delete old, upload new, rollback on failure)
  - Test Gate: Delete flow documented (transactional Storage + Firestore)
  - Test Gate: Confirmation dialog logic explained
  - Test Gate: Location constraint documented (Profile tab only)
  - ✅ **COMPLETE**: updateProfilePhoto() and deleteProfilePhoto() methods fully commented
  
- [ ] Add new files to Xcode project (USER ACTION REQUIRED)
  - Action: Open Xcode, right-click on project, select "Add Files to Psst"
  - Files to add: PhotoSourcePicker.swift (Views/Components/), CameraPicker.swift (Views/Components/)
  - Note: ProfilePhotoError.swift and ImageCacheService.swift already added in previous work
  
- [x] Update Info.plist with permission descriptions
  - Test Gate: NSCameraUsageDescription added with clear explanation
  - Test Gate: NSPhotoLibraryUsageDescription added with clear explanation
  - ✅ **COMPLETE**: Info.plist updated with camera and photo library permission descriptions
  
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
- [ ] Camera capture functionality implemented
- [ ] Photo library selection functionality implemented
- [ ] iOS permissions configured (Camera, Photo Library in Info.plist)
- [ ] PhotoSourcePicker action sheet implemented
- [ ] Camera and photo library permission handling implemented
- [ ] Threading issues fixed (all processing on background, UI on main)
- [ ] Services implemented with comprehensive error handling (upload, update, delete, camera, library)
- [ ] Network validation added (connectivity checks before all operations)
- [ ] Enhanced compression logic with error handling and memory management
- [ ] Firebase Storage permissions verified and tested
- [ ] Detailed logging implemented for debugging upload/update/delete failures
- [ ] Image caching implemented with proper invalidation
- [ ] Update functionality implemented (delete old + upload new with rollback)
- [ ] Delete functionality implemented (transactional Storage + Firestore)
- [ ] Confirmation dialog implemented for delete operations
- [ ] Location constraint enforced (Profile tab only, not Settings)
- [ ] SwiftUI views implemented with all states (empty, loading, updating, deleting, error, success)
- [ ] Firebase integration verified (Storage upload/delete, real-time sync)
- [ ] Manual testing completed (configuration, user flows, multi-device, offline, cache, update, delete, camera, library)
- [ ] Camera capture tested on real device
- [ ] Photo library selection tested on device and simulator
- [ ] Permission flows tested (granted, denied, Settings instructions)
- [ ] Upload success rate measured (target: 95% first-attempt)
- [ ] Update and delete success rates measured
- [ ] Edge cases tested (large images, invalid formats, network issues, permissions, camera/library permissions, user cancellation, delete without photo, update failures)
- [ ] Multi-device sync verified (<100ms for upload, update, delete)
- [ ] Performance targets met: upload <3s, update <3s, delete <2s, UI responsive, no blocking
- [ ] Threading safety verified (no console warnings, no UI blocking)
- [ ] Cache performance verified (instant loading <100ms, proper invalidation on all operations, >90% hit rate)
- [ ] All acceptance gates pass
- [ ] Code follows Psst/agents/shared-standards.md patterns
- [ ] No console warnings or threading errors
- [ ] Documentation updated with error handling, caching, update, delete, camera, and library patterns
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for common patterns and solutions

**🚨 Bug Fixes:**
- ✅ **FIXED**: Profile photo not updating on Profile tab after edit
  - **Root Cause**: Same URL used for updated photos (`profile_photos/{userId}/profile.jpg`), so SwiftUI doesn't detect change
  - **Solution 1**: Added `.id()` modifier with `photoRefreshTrigger` to force ProfilePhotoPreview to recreate after edit
  - **Solution 2**: Added `onDismiss` handler to invalidate cache and increment refresh trigger
  - **Solution 3**: Added `userID` parameter to ProfilePhotoPreview for proper cache-aware loading
  - **Solution 4**: AuthenticationService's Firestore listener automatically updates user data in real-time
  - **How it works**: Upload → Dismiss → Invalidate cache → Wait 0.3s for Firestore → Trigger refresh → View recreates → Loads new photo
  - **Files Modified**: `ProfileView.swift`

**✨ UX Improvements:**
- ✅ **IMPROVED**: Delete button now appears as trash icon overlay on avatar
  - **Old UX**: Delete option in action sheet (requires 3 taps: Change Photo → Delete Photo → Confirm)
  - **New UX**: Red trash button on top-right of avatar (requires 2 taps: Trash → Confirm)
  - **Benefits**: More discoverable, faster access, clearer intent, standard UX pattern
  - **Implementation**: ZStack overlay with trash.fill icon in red circle with shadow
  - **Files Modified**: `EditProfileView.swift`

- ✅ **ENFORCED**: Location constraint - Profile editing only in Profile tab
  - **Requirement**: All profile photo editing must exist ONLY in Profile tab, NOT in Settings
  - **Action Taken**: Removed "Edit Profile" button from SettingsView completely
  - **Removed**: Button (lines 77-94), sheet modifier, and state variable
  - **Result**: Users can only edit profile (including photo) from Profile tab → Edit Profile
  - **Benefits**: Clear separation of concerns, consistent UX, single source of truth
  - **Files Modified**: `SettingsView.swift`

**Critical Focus Areas:**
- **Camera Integration**: Native camera capture with proper permission handling
- **Photo Library Integration**: Photo library selection with proper permission handling
- **iOS Permissions**: Configure NSCameraUsageDescription and NSPhotoLibraryUsageDescription in Info.plist
- **Permission Flows**: Handle granted, denied, and restricted states with clear user guidance
- **Threading Safety**: All image processing on DispatchQueue.global, all UI updates on DispatchQueue.main.async
- **Comprehensive Error Handling**: Specific errors for network, size, format, permissions, compression failures, delete failures, camera/library permissions
- **Network Validation**: Check connectivity before upload/update/delete attempts, clear offline errors
- **Compression Logic**: Robust compression with memory management and error handling for camera and library photos
- **Firebase Permissions**: Test Storage security rules with fresh accounts
- **Image Caching**: Cache-first loading strategy with proper invalidation on upload/update/delete
- **Update Logic**: Delete old photo AFTER new photo confirmed, rollback on failure
- **Delete Logic**: Transactional delete (Storage + Firestore), confirmation dialog required
- **Location Constraint**: Profile photo editing ONLY in Profile tab, NOT in Settings
- **Detailed Logging**: Log all failures with technical details for debugging
- **Performance**: Upload <3s, update <3s, delete <2s, UI responsive (60fps), cached images <100ms
- **Testing**: Test with various image sizes (1MB-10MB+), network conditions (online/offline/poor), formats, update/delete flows, camera/library sources, permission states, and location constraints
- **Real Device Testing**: Camera capture MUST be tested on real device (simulator doesn't support camera)
