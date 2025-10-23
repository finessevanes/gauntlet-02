# PR-009 TODO — Basic Media Support and Image Messaging

**Branch**: `feat/pr-009-basic-media-support-and-image-messaging`  
**Source PRD**: `Psst/docs/prds/pr-009-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

- Questions: None - PRD is comprehensive
- Assumptions (confirm in PR if needed):
  - Image compression will use JPEG format for consistency
  - Thumbnail generation will be 150x150px for performance
  - Firebase Storage security rules will allow authenticated users to upload to chat folders
  - Image messages will not support text content (text-only or image-only messages)

---

## 1. Setup

- [ ] Create branch `feat/pr-009-basic-media-support-and-image-messaging` from develop
- [ ] Read PRD thoroughly
- [ ] Read `Psst/agents/shared-standards.md` for patterns
- [ ] Confirm environment and test runner work

---

## 2. Data Model & Rules

- [ ] Extend Message model with media fields
  - Test Gate: Message model compiles with new fields
- [ ] Add mediaType, mediaURL, mediaThumbnailURL, mediaSize, mediaDimensions to Message struct
  - Test Gate: All fields are optional and properly typed
- [ ] Update CodingKeys to exclude media fields from Firestore serialization (client-side only)
  - Test Gate: toDictionary() method includes media fields
- [ ] Update toDictionary() method to include media fields for Firestore writes
  - Test Gate: Media fields serialize correctly to Firestore format

---

## 3. Service Layer

Implement deterministic service contracts from PRD.

- [ ] Create ImageUploadService.swift
  - Test Gate: Service compiles and initializes without errors
- [ ] Implement image compression logic (max 2MB, 1920x1080 resolution)
  - Test Gate: Large images get compressed to under 2MB
- [ ] Implement Firebase Storage upload with progress tracking
  - Test Gate: Images upload successfully to Firebase Storage
- [ ] Implement thumbnail generation (150x150px)
  - Test Gate: Thumbnails generate correctly for various image sizes
- [ ] Add error handling for storage quota, network issues, invalid formats
  - Test Gate: All error cases handled gracefully with user-friendly messages
- [ ] Extend MessageService with sendImageMessage method
  - Test Gate: Method signature matches PRD specification
- [ ] Integrate ImageUploadService with MessageService
  - Test Gate: Image upload completes before message creation
- [ ] Update updateChatLastMessage to handle image messages
  - Test Gate: Chat lastMessage updates correctly for image messages
- [ ] Add offline queuing for image messages
  - Test Gate: Images queue locally when offline and upload when online

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [ ] Create ImagePickerView.swift
  - Test Gate: SwiftUI Preview renders; zero console errors
- [ ] Implement SwiftUI wrapper for PHPickerViewController
  - Test Gate: Image picker presents correctly
- [ ] Add camera and photo library access
  - Test Gate: Both camera and library options work
- [ ] Implement image selection callback
  - Test Gate: Selected images return to parent view
- [ ] Create ImageMessageView.swift
  - Test Gate: SwiftUI Preview renders; zero console errors
- [ ] Implement async image loading with proper error handling
  - Test Gate: Images load from URLs without blocking UI
- [ ] Add loading state with progress indicator
  - Test Gate: Loading states display during image fetch
- [ ] Add error state with retry button
  - Test Gate: Failed images show retry option
- [ ] Implement proper aspect ratio and sizing
  - Test Gate: Images display with correct proportions
- [ ] Update MessageRow.swift to display images
  - Test Gate: SwiftUI Preview renders; zero console errors
- [ ] Add conditional logic to display ImageMessageView when mediaType == "image"
  - Test Gate: Image messages show ImageMessageView, text messages show Text
- [ ] Keep existing text message display logic intact
  - Test Gate: Text messages continue to work as before
- [ ] Update ChatView.swift message input
  - Test Gate: SwiftUI Preview renders; zero console errors
- [ ] Add camera icon button next to send button
  - Test Gate: Camera button appears and is tappable
- [ ] Integrate ImagePickerView sheet presentation
  - Test Gate: Image picker sheet presents when camera button tapped
- [ ] Show image preview before sending
  - Test Gate: Selected images preview in input area
- [ ] Add upload progress indicator
  - Test Gate: Progress shows during image upload

---

## 5. Integration & Real-Time

Reference requirements from `Psst/agents/shared-standards.md`.

- [ ] Firebase Storage integration
  - Test Gate: Images upload to correct Firebase Storage paths
- [ ] Configure storage path structure: /chat-images/{chatID}/{messageID}.jpg
  - Test Gate: Images save to proper folder structure
- [ ] Set up thumbnail path: /chat-images/{chatID}/thumbnails/{messageID}_thumb.jpg
  - Test Gate: Thumbnails save to thumbnail subfolder
- [ ] Real-time listeners working for image messages
  - Test Gate: Image messages sync across devices <100ms
- [ ] Offline persistence for image messages
  - Test Gate: Images queue when offline and send when online
- [ ] Firebase Storage security rules
  - Test Gate: Only authenticated users can upload to their chat folders

---

## 6. Testing Validation

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

- [ ] Configuration Testing
  - Test Gate: Firebase Storage, camera permissions, photo library permissions all configured
  - Test Gate: All environment variables and API keys properly set
  
- [ ] User Flow Testing
  - Test Gate: Complete image selection and send flow works end-to-end
  - Test Gate: Edge cases (large images, network failures, invalid formats) handled gracefully
  
- [ ] Multi-Device Testing
  - Test Gate: Real-time image sync works across 2+ devices within 100ms
  - Test Gate: Images appear on all connected devices simultaneously
  
- [ ] Offline Behavior Testing
  - Test Gate: Images queue locally when offline and upload when connection restored
  - Test Gate: Offline image queuing works properly
  
- [ ] Visual States Verification
  - Test Gate: Loading, error, success states all render correctly for images
  - Test Gate: No console errors during image operations

---

## 7. Performance

Verify targets from `Psst/agents/shared-standards.md`.

- [ ] Image upload completes in <5 seconds
  - Test Gate: Upload time measured and meets target
- [ ] Image display renders in <1 second
  - Test Gate: Images appear quickly after upload completion
- [ ] Image compression reduces file size by >50%
  - Test Gate: Large images compressed significantly
- [ ] Smooth 60fps scrolling with image messages
  - Test Gate: Chat scrolls smoothly with mixed text/image messages
- [ ] App load time < 2-3s (unchanged with image support)
  - Test Gate: App startup time not affected by image functionality

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:
- [ ] All happy path gates pass
  - Test Gate: Image selection to send completion in <3 taps
  - Test Gate: Image loads in chat within 2 seconds
- [ ] All edge case gates pass
  - Test Gate: Large images (>2MB) get compressed automatically
  - Test Gate: Invalid image format shows error message
  - Test Gate: Network failure during upload shows retry option
- [ ] All multi-user gates pass
  - Test Gate: User A sends image → User B receives image in <100ms after upload
  - Test Gate: Multiple users can send images simultaneously
- [ ] All performance gates pass
  - Test Gate: Image upload <5 seconds, display <1 second
  - Test Gate: Image compression reduces file size by >50%

---

## 9. Documentation & PR

- [ ] Add inline code comments for complex logic
  - Test Gate: All compression, upload, and display logic documented
- [ ] Update README if needed
  - Test Gate: Any new dependencies or setup steps documented
- [ ] Create PR description (use format from Psst/agents/caleb-agent.md)
  - Test Gate: PR description includes all implementation details
- [ ] Verify with user before creating PR
  - Test Gate: User approves implementation before PR creation
- [ ] Open PR targeting develop branch
  - Test Gate: PR created successfully
- [ ] Link PRD and TODO in PR description
  - Test Gate: PR includes links to documentation

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] Message model extended with media fields
- [ ] ImageUploadService implemented with compression and upload
- [ ] MessageService extended with sendImageMessage method
- [ ] ImagePickerView and ImageMessageView components created
- [ ] MessageRow updated to display images
- [ ] ChatView updated with camera button and image picker
- [ ] Firebase Storage integration verified (upload, security rules)
- [ ] Real-time image sync verified across 2+ devices (<100ms)
- [ ] Offline image queuing tested manually
- [ ] Performance targets met (upload <5s, display <1s, compression >50%)
- [ ] All acceptance gates pass
- [ ] Manual testing completed (configuration, user flows, multi-device, offline)
- [ ] Code follows Psst/agents/shared-standards.md patterns
- [ ] No console warnings
- [ ] Documentation updated
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for common patterns and solutions
- Image compression is critical for performance - test with various image sizes
- Firebase Storage security rules must be configured before testing uploads
- Test offline behavior thoroughly as image queuing is complex
