# PR-20 TODO — Authentication UI Redesign and Color Scheme

**Branch**: `feat/pr-20-authentication-ui-redesign-and-color-scheme`  
**Source PRD**: `Psst/docs/prds/pr-20-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

- Questions: 
  - What specific gradient colors should we use? (PRD Q2 - will use weather app inspired gradients)
  - Should we implement custom animations? (PRD Q1 - will keep simple, no complex animations)
- Assumptions (confirm in PR if needed):
  - Gradient colors: Soft blues/purples for calm messaging mood (inspired by weather apps)
  - Typography: SF Pro Display for headings, SF Pro Text for body (iOS standard)
  - Button styling: Rounded corners (12pt), subtle shadows, gradient backgrounds
  - Visual clutter reduction: Remove excessive dividers, consolidate buttons, simplify forms
  - Accessibility: Maintain VoiceOver support, Dynamic Type, proper contrast ratios
  - Performance: Gradients use efficient SwiftUI rendering, no performance impact
  - All existing authentication functionality preserved (no backend changes)

---

## 1. Setup

- [ ] Create branch `feat/pr-20-authentication-ui-redesign-and-color-scheme` from develop
- [ ] Read PRD thoroughly (`Psst/docs/prds/pr-20-prd.md`)
- [ ] Read `Psst/agents/shared-standards.md` for patterns
- [ ] Verify existing authentication views are accessible
- [ ] Confirm environment and test runner work

---

## 2. Design System Components

Create new utility components for consistent design system.

### 2.1: Create ColorScheme.swift

- [ ] Create `Psst/Psst/Utilities/ColorScheme.swift`
  - Test Gate: File compiles without errors

- [ ] Define gradient color palette
  ```swift
  struct PsstColors {
      // Primary gradients for authentication screens
      static let primaryGradient = LinearGradient(
          colors: [Color(red: 0.4, green: 0.6, blue: 0.9), Color(red: 0.6, green: 0.4, blue: 0.8)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
      )
      
      // Secondary gradients for buttons
      static let buttonGradient = LinearGradient(
          colors: [Color.blue, Color.purple],
          startPoint: .leading,
          endPoint: .trailing
      )
      
      // Text colors for light/dark mode
      static let primaryText = Color.primary
      static let secondaryText = Color.secondary
  }
  ```
  - Test Gate: Color definitions compile and render in preview

- [ ] Add dark mode support
  ```swift
  static let adaptiveGradient = LinearGradient(
      colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
  )
  ```
  - Test Gate: Gradients adapt to light/dark mode

### 2.2: Create Typography.swift

- [ ] Create `Psst/Psst/Utilities/Typography.swift`
  - Test Gate: File compiles without errors

- [ ] Define text styles
  ```swift
  struct PsstTypography {
      static let largeTitle = Font.largeTitle.weight(.bold)
      static let title = Font.title.weight(.semibold)
      static let headline = Font.headline.weight(.medium)
      static let body = Font.body
      static let caption = Font.caption
  }
  ```
  - Test Gate: Typography styles compile and render correctly

- [ ] Add accessibility support
  ```swift
  static func adaptiveFont(_ style: Font, size: CGFloat) -> Font {
      return style.size(size)
  }
  ```
  - Test Gate: Dynamic Type support works

### 2.3: Create GradientBackground.swift

- [ ] Create `Psst/Psst/Views/Components/GradientBackground.swift`
  - Test Gate: File compiles without errors

- [ ] Implement reusable gradient background
  ```swift
  struct GradientBackground: View {
      let gradient: LinearGradient
      
      var body: some View {
          gradient
              .ignoresSafeArea()
      }
  }
  ```
  - Test Gate: Background renders correctly in preview

- [ ] Add animation support
  ```swift
  @State private var animationOffset: CGFloat = 0
  
  var body: some View {
      gradient
          .offset(x: animationOffset)
          .ignoresSafeArea()
          .onAppear {
              withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                  animationOffset = 10
              }
          }
  }
  ```
  - Test Gate: Subtle animation works smoothly

### 2.4: Create AuthenticationButton.swift

- [ ] Create `Psst/Psst/Views/Components/AuthenticationButton.swift`
  - Test Gate: File compiles without errors

- [ ] Implement reusable button component
  ```swift
  struct AuthenticationButton: View {
      let title: String
      let icon: String?
      let style: ButtonStyle
      let action: () -> Void
      
      enum ButtonStyle {
          case primary
          case secondary
          case google
      }
  }
  ```
  - Test Gate: Button component compiles

- [ ] Add button styling logic
  ```swift
  private var buttonBackground: some View {
      switch style {
      case .primary:
          return AnyView(PsstColors.buttonGradient)
      case .secondary:
          return AnyView(Color(.systemGray6))
      case .google:
          return AnyView(Color(.systemGray6))
      }
  }
  ```
  - Test Gate: Different button styles render correctly

- [ ] Add haptic feedback
  ```swift
  Button(action: {
      let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
      impactFeedback.impactOccurred()
      action()
  }) {
      // Button content
  }
  ```
  - Test Gate: Haptic feedback triggers on button press

---

## 3. UI Component Redesign

Redesign authentication screens with new design system.

### 3.1: Redesign LoginView.swift

- [ ] Open `Psst/Psst/Views/Authentication/LoginView.swift`
  - Test Gate: File opens, existing code visible

- [ ] Replace background with gradient
  ```swift
  ZStack {
      GradientBackground(gradient: PsstColors.primaryGradient)
      
      ScrollView {
          // Content
      }
  }
  ```
  - Test Gate: Gradient background renders correctly

- [ ] Simplify header section
  ```swift
  VStack(spacing: 16) {
      Image(systemName: "message.fill")
          .font(.system(size: 64))
          .foregroundColor(.white)
      
      Text("Welcome to Psst")
          .font(PsstTypography.largeTitle)
          .foregroundColor(.white)
      
      Text("Your secure messaging app")
          .font(PsstTypography.body)
          .foregroundColor(.white.opacity(0.8))
  }
  ```
  - Test Gate: Header renders with new typography

- [ ] Replace form with two primary buttons
  ```swift
  VStack(spacing: 16) {
      AuthenticationButton(
          title: "Sign in with Email",
          icon: "envelope.fill",
          style: .primary
      ) {
          // Show email/password form
      }
      
      AuthenticationButton(
          title: "Sign in with Google",
          icon: "g.circle.fill",
          style: .google
      ) {
          await viewModel.signInWithGoogle()
      }
  }
  ```
  - Test Gate: Two primary buttons render correctly

- [ ] Add subtle sign-up link
  ```swift
  HStack {
      Text("New to Psst?")
          .foregroundColor(.white.opacity(0.7))
      
      Button("Sign up") {
          showingSignUp = true
      }
      .foregroundColor(.white)
      .fontWeight(.semibold)
  }
  .font(PsstTypography.caption)
  ```
  - Test Gate: Sign-up link is subtle and accessible

- [ ] Remove visual clutter
  - Remove excessive dividers
  - Remove redundant Google sign-up button
  - Remove overwhelming form elements
  - Test Gate: UI element count reduced by 60%

- [ ] Add email/password form as modal
  ```swift
  .sheet(isPresented: $showingEmailSignIn) {
      EmailSignInView()
  }
  ```
  - Test Gate: Email form appears as modal

### 3.2: Create EmailSignInView.swift

- [ ] Create `Psst/Psst/Views/Authentication/EmailSignInView.swift`
  - Test Gate: File compiles without errors

- [ ] Implement email/password form
  ```swift
  struct EmailSignInView: View {
      @StateObject private var viewModel = AuthViewModel()
      @Environment(\.dismiss) private var dismiss
      
      @State private var email: String = ""
      @State private var password: String = ""
  }
  ```
  - Test Gate: Form view compiles

- [ ] Add form fields with new styling
  ```swift
  VStack(spacing: 16) {
      TextField("Email", text: $email)
          .textFieldStyle(.roundedBorder)
          .keyboardType(.emailAddress)
          .autocapitalization(.none)
      
      SecureField("Password", text: $password)
          .textFieldStyle(.roundedBorder)
  }
  ```
  - Test Gate: Form fields render correctly

- [ ] Add sign-in button
  ```swift
  AuthenticationButton(
      title: "Sign In",
      icon: nil,
      style: .primary
  ) {
      await viewModel.signIn(email: email, password: password)
  }
  .disabled(email.isEmpty || password.isEmpty)
  ```
  - Test Gate: Sign-in button works correctly

### 3.3: Update SignUpView.swift

- [ ] Open `Psst/Psst/Views/Authentication/SignUpView.swift`
  - Test Gate: File opens, existing code visible

- [ ] Replace background with gradient
  ```swift
  ZStack {
      GradientBackground(gradient: PsstColors.primaryGradient)
      
      ScrollView {
          // Content
      }
  }
  ```
  - Test Gate: Gradient background renders

- [ ] Update typography throughout
  ```swift
  Text("Create Account")
      .font(PsstTypography.largeTitle)
      .foregroundColor(.white)
  
  Text("Sign up to get started")
      .font(PsstTypography.body)
      .foregroundColor(.white.opacity(0.8))
  ```
  - Test Gate: Typography updates render correctly

- [ ] Update form styling
  ```swift
  VStack(spacing: 16) {
      TextField("Email", text: $email)
          .textFieldStyle(.roundedBorder)
          .background(Color.white.opacity(0.9))
      
      SecureField("Password", text: $password)
          .textFieldStyle(.roundedBorder)
          .background(Color.white.opacity(0.9))
  }
  ```
  - Test Gate: Form fields have consistent styling

- [ ] Update buttons with new component
  ```swift
  AuthenticationButton(
      title: "Sign Up",
      icon: nil,
      style: .primary
  ) {
      await viewModel.signUp(email: email, password: password)
  }
  ```
  - Test Gate: Buttons use new component

### 3.4: Update ForgotPasswordView.swift

- [ ] Open `Psst/Psst/Views/Authentication/ForgotPasswordView.swift`
  - Test Gate: File opens, existing code visible

- [ ] Apply consistent styling
  ```swift
  ZStack {
      GradientBackground(gradient: PsstColors.primaryGradient)
      
      VStack {
          Text("Reset Password")
              .font(PsstTypography.largeTitle)
              .foregroundColor(.white)
          
          TextField("Email", text: $email)
              .textFieldStyle(.roundedBorder)
              .background(Color.white.opacity(0.9))
          
          AuthenticationButton(
              title: "Send Reset Email",
              icon: nil,
              style: .primary
          ) {
              await viewModel.resetPassword(email: email)
          }
      }
  }
  ```
  - Test Gate: Consistent styling applied

---

## 4. Integration & Real-Time

Verify all authentication functionality preserved.

- [ ] Firebase Authentication integration
  - Test Gate: All existing auth methods work (email, Google, password reset)
  - Test Gate: Firebase configuration unchanged
  - Test Gate: Authentication state management preserved

- [ ] Real-time listeners working
  - Test Gate: User authentication state updates correctly
  - Test Gate: Navigation to main app works after sign-in

- [ ] Offline persistence
  - Test Gate: App maintains auth state when offline
  - Test Gate: Sign-in works when connection restored

---

## 5. Testing Validation

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

- [ ] Configuration Testing
  - Test Gate: Firebase Authentication, Firestore, FCM all connected and working
  - Test Gate: All environment variables and API keys properly configured
  - Test Gate: New design system components load without errors
  
- [ ] User Flow Testing
  - Test Gate: Complete sign-in flow with email/password successfully
  - Test Gate: Complete sign-in flow with Google successfully
  - Test Gate: Complete sign-up flow successfully
  - Test Gate: Password reset flow works correctly
  - Test Gate: All flows complete in < 30 seconds
  - Test Gate: Sign-in flow requires < 3 taps
  
- [ ] Multi-Device Testing
  - Test Gate: Visual design consistent on iPhone SE (small screen)
  - Test Gate: Visual design consistent on iPhone Pro Max (large screen)
  - Test Gate: Authentication works on all supported iOS versions
  - Test Gate: Gradients render correctly on all device sizes
  
- [ ] Accessibility Testing
  - Test Gate: VoiceOver navigation works correctly
  - Test Gate: Dynamic Type scaling works properly
  - Test Gate: Color contrast meets WCAG standards
  - Test Gate: All interactive elements are accessible
  
- [ ] Visual States Verification
  - Test Gate: Loading states render correctly
  - Test Gate: Error states display properly
  - Test Gate: Empty states show appropriate messaging
  - Test Gate: No console errors during testing
  - Test Gate: Visual clutter reduced by 60% (count UI elements)

---

## 6. Performance

Verify targets from `Psst/agents/shared-standards.md`.

- [ ] App load time < 2-3 seconds
  - Test Gate: Cold start to interactive measured
  - Test Gate: Gradient rendering doesn't impact load time
  
- [ ] Smooth 60fps animations
  - Test Gate: Gradient animations run smoothly
  - Test Gate: Button interactions are responsive
  
- [ ] Memory usage
  - Test Gate: No memory leaks from gradient animations
  - Test Gate: Image assets optimized

---

## 7. Acceptance Gates

Check every gate from PRD Section 12:

- [ ] All happy path gates pass
  - Test Gate: Email sign-in works
  - Test Gate: Google sign-in works
  - Test Gate: Sign-up flow works
  - Test Gate: Password reset works
  
- [ ] All edge case gates pass
  - Test Gate: Invalid credentials show appropriate errors
  - Test Gate: Network errors handled gracefully
  - Test Gate: Form validation works correctly
  
- [ ] All multi-device gates pass
  - Test Gate: Design renders correctly on 2+ device sizes
  - Test Gate: Authentication works on all supported iOS versions
  
- [ ] All performance gates pass
  - Test Gate: App load time < 2-3s maintained
  - Test Gate: Smooth transitions between screens

---

## 8. Documentation & PR

- [ ] Add inline code comments for complex logic
  - Comment gradient color choices
  - Comment typography system rationale
  - Comment accessibility considerations
  
- [ ] Update README if needed
  - Document new design system components
  - Update authentication flow documentation
  
- [ ] Create PR description (use format from Psst/agents/caleb-agent.md)
  - Include before/after screenshots
  - Document visual clutter reduction metrics
  - List all new components created
  
- [ ] Verify with user before creating PR
  - Show design improvements
  - Confirm color scheme choices
  - Validate accessibility features
  
- [ ] Open PR targeting develop branch
  - Link PRD and TODO in PR description
  - Include testing checklist

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] Design system components created (ColorScheme, Typography, GradientBackground, AuthenticationButton)
- [ ] LoginView redesigned with simplified 2-option layout
- [ ] SignUpView updated with new color scheme
- [ ] ForgotPasswordView updated with consistent styling
- [ ] Visual clutter reduced by 60% (UI element count)
- [ ] All authentication functionality preserved
- [ ] Firebase integration verified (no backend changes)
- [ ] Manual testing completed (configuration, user flows, multi-device, accessibility)
- [ ] Performance targets met (app load time < 2-3s maintained)
- [ ] All acceptance gates pass
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
- Focus on visual clutter reduction while maintaining functionality
- Ensure accessibility is not compromised by design changes
