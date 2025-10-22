# PR-17 TODO — User Profile Editing

**Branch**: `feat/pr-17-user-profile-editing`  
**Source PRD**: `Psst/docs/prds/pr-17-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

- Questions: None - PRD is comprehensive
- Assumptions (confirm in PR if needed):
  - Display name validation: 2-50 characters (confirmed in PRD)
  - Image compression target: <1MB, JPEG format (confirmed in PRD)
  - Upload timeout: <3 seconds for typical photos (confirmed in PRD)
  - Real-time sync target: <100ms across devices (confirmed in PRD)
  - Photo picker: Use native PHPicker (iOS 14+)
  - Firebase Storage bucket already configured from PR #1
  - User model already has photoURL and updatedAt fields (verified in code review)
  - Profile updates accessible from both ProfileView and SettingsView

---

## 1. Setup

- [x] Create branch `feat/pr-17-user-profile-editing` from develop
- [x] Read PRD thoroughly (`Psst/docs/prds/pr-17-prd.md`)
- [x] Read `Psst/agents/shared-standards.md` for patterns
- [ ] Verify Firebase Storage is configured in Firebase Console (will verify during manual testing)
- [x] Verify User model exists with photoURL field (from PR #3)
- [x] Verify ProfileView and SettingsView exist (from PR #4)
- [x] Confirm environment and test runner work (build succeeded)

---

## 2. Data Model Verification

Verify User model has required fields (already exists from PR #3).

- [x] Open `Psst/Psst/Models/User.swift`
  - Test Gate: File exists and compiles ✓

- [x] Verify User model has required fields:
  ```swift
  struct User {
      let id: String
      let email: String
      var displayName: String
      var photoURL: String?      // ✓ Already exists
      let createdAt: Date
      var updatedAt: Date        // ✓ Already exists
  }
  ```
  - Test Gate: All fields present, photoURL optional, updatedAt mutable ✓

- [x] Verify toDictionary() method includes photoURL and updatedAt
  - Test Gate: Method returns dict with all fields including serverTimestamp ✓

---

## 3. Service Layer - UserService Extensions

Extend UserService with profile update and photo upload methods.

### 3.1: Add updateUserProfile Method

- [ ] Open `Psst/Psst/Services/UserService.swift`
  - Test Gate: File opens, existing methods visible

- [ ] Add updateUserProfile method signature
  ```swift
  func updateUserProfile(uid: String, displayName: String?, profilePhotoURL: String?) async throws
  ```
  - Test Gate: Method signature compiles

- [ ] Implement validation logic
  - Step 1: Validate uid is not empty
  - Step 2: If displayName provided, validate 2-50 characters
  - Step 3: Throw UserServiceError.validationFailed if invalid
  - Test Gate: Validation logic compiles

- [ ] Implement Firestore update
  - Step 1: Create updateData dictionary
  - Step 2: Add displayName to dict if provided
  - Step 3: Add profilePhotoURL to dict if provided
  - Step 4: Add updatedAt: FieldValue.serverTimestamp()
  - Step 5: Call db.collection("users").document(uid).updateData(updateData)
  - Test Gate: Update logic compiles

- [ ] Add error handling and logging
  - Wrap in do-catch
  - Log update duration
  - Invalidate user cache for uid
  - Rethrow errors as UserServiceError.updateFailed
  - Test Gate: Error handling compiles

- [ ] Test updateUserProfile manually
  - Test Gate: Can update displayName successfully
  - Test Gate: Can update profilePhotoURL successfully
  - Test Gate: Validation errors work correctly
  - Test Gate: Firestore document updates within 100ms

### 3.2: Add uploadProfilePhoto Method

- [ ] Add uploadProfilePhoto method signature
  ```swift
  func uploadProfilePhoto(uid: String, imageData: Data) async throws -> String
  ```
  - Test Gate: Method signature compiles

- [ ] Add Firebase Storage import at top of file
  ```swift
  import FirebaseStorage
  ```
  - Test Gate: Import resolves without errors

- [ ] Implement image compression
  - Step 1: Check if imageData.count > 1MB (1_048_576 bytes)
  - Step 2: If too large, compress using UIImage compression
  - Step 3: Target quality: 0.7 for JPEG compression
  - Step 4: Loop until size < 1MB or quality < 0.3
  - Test Gate: Compression logic compiles

- [ ] Implement Firebase Storage upload
  - Step 1: Create storage reference: Storage.storage().reference()
  - Step 2: Create file path: "profile_photos/\(uid)/profile.jpg"
  - Step 3: Get file reference: storageRef.child(filePath)
  - Step 4: Set metadata: contentType = "image/jpeg"
  - Step 5: Upload with putDataAsync(imageData, metadata: metadata)
  - Test Gate: Upload logic compiles

- [ ] Get download URL after upload
  - Step 1: Call fileRef.downloadURL() after upload completes
  - Step 2: Return URL.absoluteString
  - Test Gate: Download URL retrieval compiles

- [ ] Add error handling and logging
  - Wrap in do-catch
  - Log upload start, compression details, upload duration
  - Throw UserServiceError with descriptive messages
  - Test Gate: Error handling compiles

- [ ] Test uploadProfilePhoto manually
  - Test Gate: Can upload small image (<1MB)
  - Test Gate: Large images compressed to <1MB
  - Test Gate: Returns valid Firebase Storage URL
  - Test Gate: Upload completes in <3 seconds
  - Test Gate: Firebase Console shows uploaded image

### 3.3: Add getCurrentUserProfile Method

- [ ] Add getCurrentUserProfile method signature
  ```swift
  func getCurrentUserProfile() async throws -> User
  ```
  - Test Gate: Method signature compiles

- [ ] Implement Firebase Auth integration
  - Step 1: Import FirebaseAuth if not already
  - Step 2: Get Auth.auth().currentUser
  - Step 3: Throw error if nil (user not authenticated)
  - Step 4: Call getUser(id: currentUser.uid)
  - Step 5: Return user object
  - Test Gate: Method compiles

- [ ] Add error handling
  - Throw UserServiceError.userNotFound if not authenticated
  - Rethrow other errors from getUser
  - Test Gate: Error handling compiles

- [ ] Test getCurrentUserProfile manually
  - Test Gate: Returns current user when authenticated
  - Test Gate: Throws error when not authenticated

---

## 4. UI Components - Supporting Components

Create reusable components for photo picking and preview.

### 4.1: Create ProfilePhotoPicker Component

- [ ] Create `Psst/Psst/Views/Components/ProfilePhotoPicker.swift`
  - Test Gate: File created in Components folder

- [ ] Add imports
  ```swift
  import SwiftUI
  import PhotosUI
  ```
  - Test Gate: Imports resolve

- [ ] Define ProfilePhotoPicker struct
  ```swift
  struct ProfilePhotoPicker: UIViewControllerRepresentable {
      @Binding var selectedImage: UIImage?
      @Environment(\.dismiss) var dismiss
  }
  ```
  - Test Gate: Struct compiles

- [ ] Implement makeUIViewController
  - Step 1: Create PHPickerConfiguration
  - Step 2: Set filter to .images only
  - Step 3: Set selectionLimit to 1
  - Step 4: Create PHPickerViewController with config
  - Step 5: Set delegate to Coordinator
  - Step 6: Return picker
  - Test Gate: Method compiles

- [ ] Implement updateUIViewController
  - Empty implementation (no updates needed)
  - Test Gate: Method compiles

- [ ] Implement makeCoordinator
  - Return Coordinator(self)
  - Test Gate: Method compiles

- [ ] Create Coordinator class
  - Inherit from NSObject, PHPickerViewControllerDelegate
  - Store parent reference
  - Implement picker(_:didFinishPicking:) delegate method
  - Parse selected image from results
  - Update parent.selectedImage binding
  - Dismiss picker
  - Test Gate: Coordinator compiles

- [ ] Test ProfilePhotoPicker in preview
  - Test Gate: SwiftUI Preview shows picker
  - Test Gate: Can select image from simulator
  - Test Gate: selectedImage binding updates

### 4.2: Create ProfilePhotoPreview Component

- [ ] Create `Psst/Psst/Views/Components/ProfilePhotoPreview.swift`
  - Test Gate: File created in Components folder

- [ ] Add imports
  ```swift
  import SwiftUI
  ```
  - Test Gate: Import resolves

- [ ] Define ProfilePhotoPreview struct
  ```swift
  struct ProfilePhotoPreview: View {
      var imageURL: String?
      var selectedImage: UIImage?
      var isLoading: Bool = false
      var size: CGFloat = 120
  }
  ```
  - Test Gate: Struct compiles

- [ ] Implement body with loading state
  - Show ProgressView if isLoading
  - Show selectedImage if present (local UIImage)
  - Show AsyncImage with imageURL if present (remote URL)
  - Show placeholder (person.circle.fill) if no image
  - Apply circular clipping and size
  - Test Gate: Body compiles

- [ ] Add styling
  - Circle frame with size parameter
  - Gray background for placeholder
  - Overlay with edit icon button area
  - Test Gate: Styling compiles

- [ ] Test ProfilePhotoPreview in preview
  - Test Gate: SwiftUI Preview shows placeholder
  - Test Gate: Loading state shows spinner
  - Test Gate: Can display UIImage
  - Test Gate: Can display URL image

---

## 5. UI Components - EditProfileView

Create main profile editing screen.

### 5.1: Create EditProfileView File

- [ ] Create `Psst/Psst/Views/Profile/EditProfileView.swift`
  - Test Gate: File created in Profile folder

- [ ] Add imports
  ```swift
  import SwiftUI
  import PhotosUI
  ```
  - Test Gate: Imports resolve

- [ ] Define EditProfileView struct
  ```swift
  struct EditProfileView: View {
      @Environment(\.dismiss) var dismiss
      @State private var displayName: String = ""
      @State private var selectedImage: UIImage? = nil
      @State private var showPhotoPicker = false
      @State private var isLoading = false
      @State private var isSaving = false
      @State private var errorMessage: String? = nil
      @State private var showError = false
      
      var user: User
  }
  ```
  - Test Gate: Struct compiles with all state properties

### 5.2: Implement EditProfileView Body

- [ ] Create NavigationView structure
  - Add navigation title "Edit Profile"
  - Add Cancel button (leading)
  - Add Save button (trailing, disabled when saving)
  - Test Gate: Navigation structure compiles

- [ ] Add Form with sections
  - Section 1: Profile photo preview and change button
  - Section 2: Display name TextField
  - Test Gate: Form structure compiles

- [ ] Implement profile photo section
  - Show ProfilePhotoPreview with current/selected image
  - Show "Change Photo" button that sets showPhotoPicker = true
  - Show loading spinner during upload
  - Test Gate: Photo section compiles

- [ ] Implement display name section
  - TextField bound to $displayName
  - Placeholder: "Enter display name"
  - Character counter: "\(displayName.count)/50"
  - Validation error text if invalid
  - Test Gate: Name section compiles

- [ ] Add sheet for photo picker
  ```swift
  .sheet(isPresented: $showPhotoPicker) {
      ProfilePhotoPicker(selectedImage: $selectedImage)
  }
  ```
  - Test Gate: Sheet modifier compiles

- [ ] Add error alert
  ```swift
  .alert("Error", isPresented: $showError) {
      Button("OK") { }
  } message: {
      Text(errorMessage ?? "An error occurred")
  }
  ```
  - Test Gate: Alert compiles

### 5.3: Implement Save Functionality

- [ ] Add onAppear to load current user data
  ```swift
  .onAppear {
      displayName = user.displayName
  }
  ```
  - Test Gate: onAppear compiles

- [ ] Create saveProfile async function
  - Step 1: Set isSaving = true
  - Step 2: Validate displayName (2-50 chars)
  - Step 3: If invalid, show error and return
  - Step 4: Upload image if selectedImage != nil
  - Step 5: Call UserService.shared.uploadProfilePhoto
  - Step 6: Get photoURL from upload result
  - Step 7: Call UserService.shared.updateUserProfile
  - Step 8: Set isSaving = false
  - Step 9: Dismiss view on success
  - Step 10: Show error on failure
  - Test Gate: saveProfile function compiles

- [ ] Wire Save button to saveProfile
  ```swift
  Button("Save") {
      Task {
          await saveProfile()
      }
  }
  .disabled(isSaving || !hasChanges())
  ```
  - Test Gate: Button action compiles

- [ ] Create hasChanges helper function
  - Returns true if displayName != user.displayName || selectedImage != nil
  - Test Gate: Helper function compiles

- [ ] Test EditProfileView in preview
  - Test Gate: SwiftUI Preview renders
  - Test Gate: Form fields interactive
  - Test Gate: Save button enables/disables correctly

---

## 6. Update Existing Views

Integrate profile editing into existing app screens.

### 6.1: Update ProfileView

- [ ] Open `Psst/Psst/Views/Profile/ProfileView.swift`
  - Test Gate: File opens

- [ ] Add state for current user
  ```swift
  @EnvironmentObject var authViewModel: AuthViewModel
  @State private var showEditProfile = false
  ```
  - Test Gate: State variables compile

- [ ] Replace placeholder content with real profile display
  - Show profile photo (ProfilePhotoPreview)
  - Show display name
  - Show email
  - Show "Edit Profile" button
  - Test Gate: Content layout compiles

- [ ] Add sheet for EditProfileView
  ```swift
  .sheet(isPresented: $showEditProfile) {
      if let user = authViewModel.currentUser {
          EditProfileView(user: user)
      }
  }
  ```
  - Test Gate: Sheet modifier compiles

- [ ] Wire "Edit Profile" button
  ```swift
  Button("Edit Profile") {
      showEditProfile = true
  }
  ```
  - Test Gate: Button compiles

- [ ] Test ProfileView manually
  - Test Gate: Profile displays current user info
  - Test Gate: "Edit Profile" button shows EditProfileView sheet
  - Test Gate: Can navigate between ProfileView and EditProfileView

### 6.2: Update SettingsView

- [ ] Open `Psst/Psst/Views/Settings/SettingsView.swift`
  - Test Gate: File opens

- [ ] Add state for edit profile sheet
  ```swift
  @State private var showEditProfile = false
  ```
  - Test Gate: State variable compiles

- [ ] Add "Edit Profile" button above logout button
  ```swift
  Button(action: { showEditProfile = true }) {
      HStack {
          Image(systemName: "person.circle.fill")
          Text("Edit Profile")
              .fontWeight(.semibold)
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(Color.blue)
      .foregroundColor(.white)
      .cornerRadius(12)
  }
  ```
  - Test Gate: Button compiles

- [ ] Add sheet for EditProfileView
  ```swift
  .sheet(isPresented: $showEditProfile) {
      if let user = authViewModel.currentUser {
          EditProfileView(user: user)
      }
  }
  ```
  - Test Gate: Sheet modifier compiles

- [ ] Test SettingsView manually
  - Test Gate: "Edit Profile" button visible
  - Test Gate: Button shows EditProfileView sheet
  - Test Gate: Sheet dismisses after save/cancel

### 6.3: Update ChatRowView to Display Profile Photos

- [ ] Open `Psst/Psst/Views/ChatList/ChatRowView.swift`
  - Test Gate: File opens

- [ ] Add AsyncImage for profile photo
  - Step 1: Fetch other user from chat.members
  - Step 2: Load user profile with UserService
  - Step 3: Display user.photoURL in AsyncImage
  - Step 4: Show placeholder if no photo
  - Step 5: Apply circular clipping (40x40)
  - Test Gate: Profile photo layout compiles

- [ ] Add state for user profile
  ```swift
  @State private var otherUser: User? = nil
  ```
  - Test Gate: State compiles

- [ ] Load user in onAppear
  ```swift
  .onAppear {
      Task {
          // Get other user ID from chat.members
          // Fetch user with UserService
          // Set otherUser state
      }
  }
  ```
  - Test Gate: onAppear compiles

- [ ] Test ChatRowView manually
  - Test Gate: Profile photos display in chat list
  - Test Gate: Placeholder shows if no photo
  - Test Gate: Images load asynchronously

### 6.4: Update ChatView to Display Profile Photos

- [ ] Open `Psst/Psst/Views/ChatList/ChatView.swift`
  - Test Gate: File opens

- [ ] Add profile photo to navigation bar
  - Show AsyncImage in toolbar
  - Load other user's photoURL
  - Apply small circular frame (32x32)
  - Show placeholder if no photo
  - Test Gate: Toolbar photo compiles

- [ ] Add state for other user
  ```swift
  @State private var otherUser: User? = nil
  ```
  - Test Gate: State compiles

- [ ] Load user in onAppear
  - Similar to ChatRowView
  - Fetch other user from chat.members
  - Test Gate: Load logic compiles

- [ ] Test ChatView manually
  - Test Gate: Profile photo shows in chat header
  - Test Gate: Photo updates when profile changes
  - Test Gate: Layout doesn't break with/without photo

---

## 7. Firebase Storage Configuration

Configure Firebase Storage security rules.

### 7.1: Create Storage Rules File

- [ ] Check if `firebase-storage-rules.rules` exists in project root
  - Test Gate: File location identified

- [ ] Create or update storage rules file
  ```
  rules_version = '2';
  service firebase.storage {
    match /b/{bucket}/o {
      // Profile photos - users can only write their own
      match /profile_photos/{userId}/{allPaths=**} {
        allow read: if true;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
  ```
  - Test Gate: Rules file created/updated

- [ ] Document storage rules in code comments
  - Explain: Public read, authenticated write to own folder
  - Test Gate: Documentation clear

### 7.2: Deploy Storage Rules

- [ ] Deploy rules to Firebase
  - Option 1: Use Firebase Console UI to paste rules
  - Option 2: Use Firebase CLI: `firebase deploy --only storage`
  - Test Gate: Rules deployed successfully

- [ ] Verify rules in Firebase Console
  - Navigate to Storage → Rules tab
  - Confirm rules are active
  - Test Gate: Rules visible in console

- [ ] Test storage rules manually
  - Test Gate: Authenticated user can upload to their own profile_photos/{uid}/
  - Test Gate: User cannot upload to another user's folder
  - Test Gate: Anyone can read profile photos

---

## 8. Real-time Sync Integration

Add real-time listeners for profile updates across app.

### 8.1: Add Profile Listener to ChatRowView

- [ ] Replace static user fetch with real-time listener
  - Use UserService.shared.observeUser(id:) instead of getUser
  - Update otherUser state when profile changes
  - Store ListenerRegistration for cleanup
  - Test Gate: Listener implementation compiles

- [ ] Add onDisappear cleanup
  ```swift
  .onDisappear {
      userListener?.remove()
  }
  ```
  - Test Gate: Cleanup compiles

- [ ] Test real-time sync manually
  - Test Gate: Chat row updates when profile photo changes
  - Test Gate: Display name updates in real-time
  - Test Gate: Updates appear within 100ms

### 8.2: Add Profile Listener to ChatView

- [ ] Replace static user fetch with real-time listener
  - Similar to ChatRowView
  - Use observeUser for other user
  - Update UI when profile changes
  - Test Gate: Listener compiles

- [ ] Add cleanup in onDisappear
  - Remove listener registration
  - Test Gate: Cleanup compiles

- [ ] Test real-time sync manually
  - Test Gate: Chat header updates when profile changes
  - Test Gate: Updates sync across devices
  - Test Gate: Latency < 100ms

### 8.3: Add Profile Listener to ProfileView

- [ ] Add real-time listener for current user
  - Listen to authViewModel.currentUser updates
  - Refresh display when profile changes
  - Test Gate: Listener compiles

- [ ] Test real-time sync manually
  - Test Gate: ProfileView updates after editing
  - Test Gate: Changes visible immediately after save
  - Test Gate: No manual refresh needed

---

## 9. Manual Testing Validation

Complete comprehensive manual testing per `Psst/agents/shared-standards.md`.

### 9.1: Configuration Testing

- [ ] Verify Firebase Storage configured
  - Test Gate: Storage bucket exists in Firebase Console
  - Test Gate: Can access Storage from app
  - Test Gate: Security rules deployed and active

- [ ] Verify Firestore connection
  - Test Gate: Can read/write user documents
  - Test Gate: Real-time listeners work

- [ ] Verify all imports resolve
  - Test Gate: No compiler errors
  - Test Gate: All Firebase imports work

### 9.2: User Flow Testing - Display Name Update

- [ ] Test happy path
  - Open EditProfileView from ProfileView
  - Change display name to valid value
  - Click Save
  - Test Gate: Save succeeds, view dismisses
  - Test Gate: New name visible in ProfileView
  - Test Gate: New name visible in chat list
  - Test Gate: New name visible in chat headers

- [ ] Test validation errors
  - Try empty display name
  - Test Gate: Error shown, save disabled
  - Try 1-character name
  - Test Gate: Error shown, save disabled
  - Try 51-character name
  - Test Gate: Error shown, save disabled
  - Try valid 2-50 character name
  - Test Gate: Save enabled, succeeds

### 9.3: User Flow Testing - Profile Photo Upload

- [ ] Test photo selection
  - Click "Change Photo" button
  - Test Gate: Photo picker appears
  - Select photo from library
  - Test Gate: Preview updates with selected photo

- [ ] Test photo upload - small image
  - Select small image (<1MB)
  - Click Save
  - Test Gate: Upload completes in <3 seconds
  - Test Gate: Photo appears in ProfileView
  - Test Gate: Photo appears in chat list
  - Test Gate: Photo appears in chat headers

- [ ] Test photo upload - large image
  - Select large image (>1MB, e.g., 5MB photo)
  - Click Save
  - Test Gate: Image compressed automatically
  - Test Gate: Compressed size <1MB
  - Test Gate: Upload completes in <3 seconds
  - Test Gate: Image quality acceptable

### 9.4: Multi-Device Testing

- [ ] Test profile sync across 2 devices
  - Device 1: Update display name
  - Test Gate: Device 2 shows new name in <100ms
  - Device 1: Upload profile photo
  - Test Gate: Device 2 shows new photo in <100ms

- [ ] Test with 3+ devices if available
  - Update profile on Device 1
  - Test Gate: All devices sync within 100ms

- [ ] Test concurrent updates
  - Device 1 and Device 2 update profile simultaneously
  - Test Gate: Last write wins, no crashes
  - Test Gate: Both devices eventually consistent

### 9.5: Edge Cases Testing

- [ ] Test offline behavior
  - Disable internet on device
  - Try to save profile changes
  - Test Gate: Error shown gracefully
  - Re-enable internet
  - Test Gate: Can retry save successfully

- [ ] Test network failure during upload
  - Start photo upload
  - Disable internet mid-upload
  - Test Gate: Error shown, no partial save
  - Re-enable internet
  - Test Gate: Can retry upload

- [ ] Test invalid image formats
  - Try to select non-image file (if possible)
  - Test Gate: Handled gracefully or filtered out

- [ ] Test app backgrounding during upload
  - Start upload, background app immediately
  - Test Gate: Upload continues or fails gracefully
  - Test Gate: No app crash

### 9.6: Performance Testing

- [ ] Measure image upload time
  - Upload 1MB image
  - Test Gate: Completes in <3 seconds
  - Upload 5MB image (before compression)
  - Test Gate: Compression + upload in <3 seconds

- [ ] Measure profile sync latency
  - Update profile on Device 1
  - Measure time until visible on Device 2
  - Test Gate: Latency <100ms

- [ ] Verify app responsiveness
  - During photo upload, interact with UI
  - Test Gate: App remains responsive, no freezing
  - Test Gate: Can navigate away during upload

### 9.7: Visual States Verification

- [ ] Verify all UI states render correctly
  - Empty state: No profile photo, placeholder shown
  - Test Gate: Placeholder displays correctly
  - Loading state: During upload
  - Test Gate: Spinner shows, Save button disabled
  - Error state: Validation or network error
  - Test Gate: Error message clear and helpful
  - Success state: After successful save
  - Test Gate: View dismisses, changes visible

- [ ] Check console for errors
  - Test Gate: No console errors during normal flow
  - Test Gate: Errors logged clearly for debugging

---

## 10. Documentation & PR

### 10.1: Add Code Comments

- [ ] Review UserService additions
  - Add doc comments for uploadProfilePhoto
  - Add doc comments for updateUserProfile
  - Explain compression logic
  - Document error cases
  - Test Gate: All public methods documented

- [ ] Review EditProfileView
  - Add comments for complex logic
  - Document state management
  - Explain validation rules
  - Test Gate: Code clear and maintainable

- [ ] Review component files
  - Document ProfilePhotoPicker usage
  - Document ProfilePhotoPreview props
  - Test Gate: Components easy to understand

### 10.2: Create PR Description

- [ ] Write PR description following format:
  ```markdown
  # PR #17: User Profile Editing
  
  ## Summary
  Implements user profile editing with display name and photo upload functionality.
  
  ## Changes
  - Extended UserService with updateUserProfile and uploadProfilePhoto methods
  - Created EditProfileView with form validation and photo picker
  - Added ProfilePhotoPicker and ProfilePhotoPreview components
  - Updated ProfileView and SettingsView with edit profile navigation
  - Updated ChatRowView and ChatView to display profile photos
  - Configured Firebase Storage security rules
  - Implemented real-time profile sync across all screens
  
  ## Testing
  - Manual testing completed per shared-standards.md
  - Configuration: Firebase Storage, Firestore ✓
  - User flows: Display name update, photo upload ✓
  - Multi-device sync: <100ms latency ✓
  - Edge cases: Validation, offline, large images ✓
  - Performance: Upload <3s, sync <100ms ✓
  
  ## Links
  - PRD: Psst/docs/prds/pr-17-prd.md
  - TODO: Psst/docs/todos/pr-17-todo.md
  
  ## Screenshots
  [Add screenshots of EditProfileView, profile display]
  ```
  - Test Gate: Description complete

### 10.3: Verify with User

- [ ] Present completed work to user
  - Show all implemented features
  - Demonstrate profile editing flow
  - Show multi-device sync
  - Present test results
  - Test Gate: User reviews and approves

### 10.4: Create PR

- [ ] Verify all TODO tasks completed
  - Test Gate: All checkboxes checked

- [ ] Commit all changes with clear messages
  ```bash
  git add .
  git commit -m "feat(pr-17): Implement user profile editing with photo upload
  
  - Add UserService.updateUserProfile and uploadProfilePhoto methods
  - Create EditProfileView with form validation
  - Add ProfilePhotoPicker and ProfilePhotoPreview components
  - Update ProfileView, SettingsView, ChatRowView, ChatView
  - Configure Firebase Storage security rules
  - Implement real-time profile sync across app
  - Complete manual testing validation
  
  Fixes: PR #17"
  ```
  - Test Gate: Changes committed

- [ ] Push branch to remote
  ```bash
  git push origin feat/pr-17-user-profile-editing
  ```
  - Test Gate: Branch pushed successfully

- [ ] Create pull request on GitHub
  - Target branch: `develop`
  - Title: "PR #17: User Profile Editing"
  - Description: Use prepared PR description
  - Link PRD and TODO
  - Test Gate: PR created successfully

- [ ] Request review (if applicable)
  - Test Gate: PR ready for review

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] UserService extended with updateUserProfile and uploadProfilePhoto
- [ ] EditProfileView created with form validation and photo picker
- [ ] ProfilePhotoPicker and ProfilePhotoPreview components created
- [ ] ProfileView and SettingsView updated with edit profile navigation
- [ ] ChatRowView and ChatView updated to display profile photos
- [ ] Firebase Storage security rules configured and deployed
- [ ] Real-time profile sync implemented across all screens
- [ ] Manual testing completed (configuration, user flows, multi-device, offline)
- [ ] Image upload <3s, profile sync <100ms
- [ ] All validation and edge cases tested
- [ ] Code follows Psst/agents/shared-standards.md patterns
- [ ] No console warnings or errors
- [ ] Documentation and code comments added
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for common patterns and solutions
- Use background threads for image compression and upload (see Swift threading rules)
- Always update UI on main thread after async operations

