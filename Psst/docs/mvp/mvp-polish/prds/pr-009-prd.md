# PRD: Basic Media Support and Image Messaging

**Feature**: basic-media-support-and-image-messaging

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam

**Target Release**: Phase 1 (MVP Polish)

**Links**: [PR Brief], [TODO], [Designs], [Tracking Issue]

---

## 1. Summary

Implement basic media support to allow users to send and receive images in conversations, including image picker functionality, Firebase Storage upload, inline display, and proper compression for optimal performance.

---

## 2. Problem & Goals

- **User Problem**: Users cannot share images in conversations, limiting the messaging experience to text-only communication
- **Why Now**: Essential for a complete messaging experience and core requirement for modern messaging apps
- **Goals (ordered, measurable)**:
  - [ ] G1 — Users can select and send images from photo library or camera
  - [ ] G2 — Images display inline in chat with proper sizing and aspect ratio
  - [ ] G3 — Images upload to Firebase Storage with compression and error handling

---

## 3. Non-Goals / Out of Scope

- [ ] Video support (future enhancement)
- [ ] Image editing capabilities (crop, filters, etc.)
- [ ] Multiple image selection in single message
- [ ] Image sharing from other apps
- [ ] Advanced image compression algorithms beyond basic resizing

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:
- **User-visible**: Image selection to send completion in <3 taps, image loads in chat within 2 seconds
- **System**: Image upload completes in <5 seconds, image display renders in <1 second
- **Quality**: 0 blocking bugs, all acceptance gates pass, crash-free rate >99%

---

## 5. Users & Stories

- As a **messaging user**, I want to **select and send images from my photo library** so that **I can share visual content with friends**
- As a **messaging user**, I want to **take photos with my camera and send them** so that **I can share real-time moments**
- As a **messaging user**, I want to **see images inline in chat conversations** so that **I can view shared content without leaving the app**
- As a **messaging user**, I want to **receive images with proper loading states** so that **I know when content is loading vs failed**

---

## 6. Experience Specification (UX)

- **Entry points**: Camera button in message input, photo library access via image picker
- **Visual behavior**: Images display inline with message bubbles, proper aspect ratio maintained
- **Loading/disabled/error states**: 
  - Loading: Spinner or progress indicator during upload
  - Error: Retry button with clear error message
  - Success: Image displays with timestamp
- **Performance**: See targets in `Psst/agents/shared-standards.md` - images load in <1 second, upload in <5 seconds

---

## 7. Functional Requirements (Must/Should)

- **MUST**: Image picker integration (photo library + camera access)
- **MUST**: Firebase Storage upload with proper security rules
- **MUST**: Image compression before upload (max 2MB, 1920x1080 resolution)
- **MUST**: Inline image display in chat messages
- **MUST**: Error handling for failed uploads with retry mechanism
- **SHOULD**: Thumbnail generation for better performance
- **SHOULD**: Optimistic UI (show image immediately, then confirm upload)

**Acceptance gates per requirement**:
- [Gate] When User A selects image → Image appears in chat within 2 seconds
- [Gate] When User A sends image → User B receives image in <100ms after upload completes
- [Gate] Error case: Failed upload shows retry button; no partial image display
- [Gate] Offline: Images queue and upload when connection restored

---

## 8. Data Model

**New Message Document Structure**:
```swift
{
  id: String,
  text: String?,
  senderID: String,
  timestamp: Timestamp,
  readBy: [String],
  // New fields for media support
  mediaType: String?, // "image", "video", etc.
  mediaURL: String?, // Firebase Storage URL
  mediaThumbnailURL: String?, // Thumbnail URL for performance
  mediaSize: Int?, // File size in bytes
  mediaDimensions: [String: Int]? // {"width": 1920, "height": 1080}
}
```

**Validation rules**: 
- mediaType must be "image" for this PR
- mediaURL required when mediaType is present
- mediaSize must be <2MB
- Firebase security rules: Users can only upload to their own chat folders

**Indexing/queries**: 
- Firestore listeners for real-time image updates
- Composite index on (chatID, timestamp) for message ordering

---

## 9. API / Service Contracts

```swift
// Image upload service
func uploadImage(imageData: Data, chatID: String) async throws -> String // Returns mediaURL
func compressImage(_ image: UIImage, maxSize: Int = 2_000_000) -> Data
func generateThumbnail(from imageData: Data) -> Data

// Message service extensions
func sendImageMessage(chatID: String, imageData: Data) async throws -> String
func observeMessages(chatID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration
```

**Pre/post-conditions**:
- uploadImage: Requires valid image data, user authentication, chat membership
- sendImageMessage: Returns message ID, updates chat lastMessage
- Error handling: Network errors, storage quota exceeded, invalid image format

---

## 10. UI Components to Create/Modify

- `Views/Conversation/MessageInputView.swift` — Add camera button and image picker
- `Views/Conversation/MessageRow.swift` — Add image display logic
- `Components/ImageMessageView.swift` — New component for image display
- `Components/ImagePickerView.swift` — New component for image selection
- `Services/ImageUploadService.swift` — New service for image handling
- `Services/MessageService.swift` — Extend with image message support
- `Models/Message.swift` — Add media fields to Message model

---

## 11. Integration Points

- **Firebase Authentication**: Verify user permissions for image upload
- **Firebase Storage**: Image upload with security rules
- **Firestore**: Message document updates with media metadata
- **FCM**: Push notifications for image messages
- **State management**: SwiftUI @State for image picker, @StateObject for upload progress

---

## 12. Testing Plan & Acceptance Gates

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

- **Configuration Testing**
  - [ ] Firebase Storage setup works
  - [ ] Image picker permissions granted
  - [ ] Camera access permissions granted
  - [ ] All environment variables properly set
  
- **Happy Path Testing**
  - [ ] User selects image from library → Image appears in chat
  - [ ] Gate: Image displays within 2 seconds of selection
  - [ ] User takes photo with camera → Photo appears in chat
  - [ ] Gate: Image upload completes in <5 seconds
  
- **Edge Cases Testing**
  - [ ] Large image (>2MB) gets compressed automatically
  - [ ] Invalid image format shows error message
  - [ ] Network failure during upload shows retry option
  - [ ] Empty photo library shows appropriate empty state
  
- **Multi-User Testing**
  - [ ] User A sends image → User B receives image in <100ms after upload
  - [ ] Multiple users can send images simultaneously
  - [ ] Images appear on all connected devices
  
- **Performance Testing** (see shared-standards.md)
  - [ ] App load < 2-3s (unchanged with image support)
  - [ ] Smooth 60fps scrolling with image messages
  - [ ] Image compression reduces file size by >50%

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:
- [ ] Image picker service implemented with proper error handling
- [ ] Firebase Storage integration with security rules
- [ ] SwiftUI views with all states (loading, error, success, empty)
- [ ] Real-time image sync verified across 2+ devices
- [ ] Offline image queuing tested manually
- [ ] All acceptance gates pass
- [ ] Manual testing completed (configuration, user flows, multi-device, offline)
- [ ] Image compression and performance optimized
- [ ] Documentation updated

---

## 14. Risks & Mitigations

- **Risk**: Large images slow down app → **Mitigation**: Aggressive compression (2MB max, 1920x1080 max)
- **Risk**: Firebase Storage costs → **Mitigation**: Image compression, thumbnail generation
- **Risk**: Network failures during upload → **Mitigation**: Retry mechanism, offline queuing
- **Risk**: Memory issues with large images → **Mitigation**: Proper image resizing, lazy loading
- **Risk**: Security vulnerabilities → **Mitigation**: Firebase Storage security rules, user authentication

---

## 15. Rollout & Telemetry

- **Feature flag**: No (core messaging feature)
- **Metrics**: Image upload success rate, upload time, compression ratio, error rates
- **Manual validation steps**: Test image selection, upload, display, and multi-device sync

---

## 16. Open Questions

- Q1: Should we support animated GIFs? (Defer to future PR)
- Q2: What's the maximum number of images per chat? (No limit for this PR)

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Video message support
- [ ] Image editing (crop, filters, annotations)
- [ ] Multiple image selection
- [ ] Image sharing from other apps
- [ ] Advanced compression algorithms
- [ ] Image search within conversations

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** User can select image from library and send it to another user who receives it in their chat
2. **Primary user and critical action?** Messaging user selecting and sending images
3. **Must-have vs nice-to-have?** Must-have: Image selection, upload, display. Nice-to-have: Thumbnails, advanced compression
4. **Real-time requirements?** Images must sync across devices in <100ms after upload completes
5. **Performance constraints?** Image upload <5 seconds, display <1 second, compression to <2MB
6. **Error/edge cases to handle?** Network failures, large images, invalid formats, storage quota
7. **Data model changes?** Add media fields to Message model, Firebase Storage integration
8. **Service APIs required?** Image upload service, compression service, extended message service
9. **UI entry points and states?** Camera button in message input, image picker modal, inline image display
10. **Security/permissions implications?** Camera access, photo library access, Firebase Storage security rules
11. **Dependencies or blocking integrations?** PR #8 (messaging service), PR #17 (user profile editing for image handling)
12. **Rollout strategy and metrics?** No feature flag needed, track upload success and performance
13. **What is explicitly out of scope?** Video support, image editing, multiple selection, external app sharing

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `Psst/agents/shared-standards.md` throughout
