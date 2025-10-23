# Product Backlog

## Known Issues

### Image Scrolling Issue
- **Issue**: Unable to scroll over images in chat messages
- **Description**: When users try to scroll the conversation by swiping on images, the scroll gesture is not recognized. Users cannot scroll the conversation when their finger is over an image.
- **Expected Behavior**: Should work like native Messages app where you can scroll the conversation by swiping anywhere, including on images
- **Current Status**: Open
- **Priority**: High
- **Affected Components**: 
  - `ImageMessageView.swift`
  - `RobustImageLoader` in `ImageMessageView.swift`
  - Chat scroll view interaction

### Full-Screen Image Functionality
- **Status**: ✅ Implemented
- **Description**: Users can tap images to view them in full-screen with zoom/pan capabilities
- **Components**: `FullScreenImageView.swift`

---

## Future Enhancements

*Items to be added as they are identified*
