//
//  AuthenticationUITests.swift
//  PsstUITests
//
//  Created by Caleb (Coder Agent) - PR #2
//  UI tests for authentication flows
//

import XCTest

/// UI tests for authentication user flows
/// Tests login, sign up, and forgot password screens
final class AuthenticationUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override class func setUp() {
        super.setUp()
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        
        // Only launch if not already running - HUGE performance boost!
        if !app.exists || app.state != .runningForeground {
            app.launch()
        }
        
        // Reset to initial state instead of relaunching
        // Dismiss any open sheets
        let maxAttempts = 3
        var attempts = 0
        
        // Close any sign-up or forgot password sheets
        while attempts < maxAttempts {
            if app.buttons["xmark"].firstMatch.exists {
                app.buttons["xmark"].firstMatch.tap()
                Thread.sleep(forTimeInterval: 0.3)
            } else if app.buttons["Back to Sign In"].exists {
                app.buttons["Back to Sign In"].tap()
                Thread.sleep(forTimeInterval: 0.3)
            } else {
                break
            }
            attempts += 1
        }
    }
    
    override func tearDownWithError() throws {
        // Don't set app to nil - keep it running for next test
        try super.tearDownWithError()
    }
    
    // MARK: - Login View Tests
    
    /// Test: Login View Displays Correctly
    /// Verifies that all login screen elements are visible
    func testLoginView_DisplaysCorrectly() throws {
        XCTContext.runActivity(named: "Test: Login View Displays Correctly") { _ in
            // Given: App launches
            // When: Login view is displayed
            
            // Then: Should show all required elements
            XCTAssertTrue(app.staticTexts["Welcome Back"].exists)
            XCTAssertTrue(app.staticTexts["Sign in to continue"].exists)
            XCTAssertTrue(app.textFields["loginEmailField"].exists)
            XCTAssertTrue(app.secureTextFields["loginPasswordField"].exists)
            XCTAssertTrue(app.buttons["Sign In"].exists)
            XCTAssertTrue(app.buttons["Sign in with Google"].exists)
            XCTAssertTrue(app.buttons["Forgot Password?"].exists)
            XCTAssertTrue(app.buttons["Sign up with Google"].exists)
            XCTAssertTrue(app.buttons["Email"].exists) // Email signup link
        }
    }
    
    /// Test: Login View Sign In Button Disabled When Fields Empty
    /// Verifies that sign in button is disabled when email or password is empty
    func testLoginView_SignInButton_DisabledWhenFieldsEmpty() throws {
        XCTContext.runActivity(named: "Test: Login View Sign In Button Disabled When Fields Empty") { _ in
            // Given: Login view with empty fields
            let signInButton = app.buttons["Sign In"]
            
            // Then: Sign in button should be disabled
            XCTAssertFalse(signInButton.isEnabled)
        }
    }
    
    /// Test: Login View Sign In Button Enabled When Fields Filled
    /// Verifies that sign in button becomes enabled when both fields are filled
    func testLoginView_SignInButton_EnabledWhenFieldsFilled() throws {
        XCTContext.runActivity(named: "Test: Login View Sign In Button Enabled When Fields Filled") { _ in
            // Given: Login view
            let emailField = app.textFields["loginEmailField"]
            let passwordField = app.secureTextFields["loginPasswordField"]
            let signInButton = app.buttons["Sign In"]
            
            // When: Entering email and password (shorter for speed)
            emailField.tap()
            emailField.typeText("a@b.c")
            
            passwordField.tap()
            passwordField.typeText("pass123")
            
            // Then: Sign in button should be enabled
            XCTAssertTrue(signInButton.isEnabled)
        }
    }
    
    /// Test: Login View Google Sign In Button Exists
    /// Verifies that Google sign-in button is visible and enabled
    func testLoginView_GoogleSignInButton_Exists() throws {
        XCTContext.runActivity(named: "Test: Login View Google Sign In Button Exists") { _ in
            // Given: Login view
            let googleButton = app.buttons["Sign in with Google"]
            
            // Then: Google sign-in button should exist and be enabled
            XCTAssertTrue(googleButton.exists)
            XCTAssertTrue(googleButton.isEnabled)
        }
    }
    
    /// Test: Login View Forgot Password Button Opens Sheet
    /// Verifies that tapping forgot password opens the password reset sheet
    func testLoginView_ForgotPasswordButton_OpensSheet() throws {
        XCTContext.runActivity(named: "Test: Login View Forgot Password Button Opens Sheet") { _ in
            // Given: Login view
            let forgotPasswordButton = app.buttons["Forgot Password?"]
            
            // When: Tapping forgot password
            forgotPasswordButton.tap()
            
            // Then: Forgot password sheet should appear
            XCTAssertTrue(app.staticTexts["Reset Password"].waitForExistence(timeout: 1))
        }
    }
    
    /// Test: Login View Email Sign Up Button Opens Sheet
    /// Verifies that tapping email sign up opens the registration sheet
    func testLoginView_EmailSignUpButton_OpensSheet() throws {
        XCTContext.runActivity(named: "Test: Login View Email Sign Up Button Opens Sheet") { _ in
            // Given: Login view
            let emailSignUpButton = app.buttons["Email"]
            
            // When: Tapping email sign up
            emailSignUpButton.tap()
            
            // Then: Sign up sheet should appear
            XCTAssertTrue(app.staticTexts["Create Account"].waitForExistence(timeout: 1))
        }
    }
    
    // MARK: - Sign Up View Tests
    
    /// Test: Sign Up View Displays Correctly
    /// Verifies that all sign up screen elements are visible
    func testSignUpView_DisplaysCorrectly() throws {
        XCTContext.runActivity(named: "Test: Sign Up View Displays Correctly") { _ in
            // Given: Login view
            let emailSignUpButton = app.buttons["Email"]
            
            // When: Opening sign up sheet
            emailSignUpButton.tap()
            
            // Wait for sheet to appear
            XCTAssertTrue(app.staticTexts["Create Account"].waitForExistence(timeout: 1))
            
            // Then: Should show all required elements
            XCTAssertTrue(app.staticTexts["Sign up to get started"].exists)
            XCTAssertTrue(app.textFields["signUpEmailField"].exists)
            XCTAssertTrue(app.secureTextFields["signUpPasswordField"].exists)
            XCTAssertTrue(app.secureTextFields["signUpConfirmPasswordField"].exists)
            XCTAssertTrue(app.buttons["Sign Up"].exists)
            XCTAssertTrue(app.buttons["Sign up with Google"].exists)
        }
    }
    
    /// Test: Sign Up View Sign Up Button Disabled When Fields Empty
    /// Verifies that sign up button is disabled when fields are empty
    func testSignUpView_SignUpButton_DisabledWhenFieldsEmpty() throws {
        XCTContext.runActivity(named: "Test: Sign Up View Sign Up Button Disabled When Fields Empty") { _ in
            // Given: Sign up view with empty fields
            app.buttons["Email"].tap() // Open sheet
            
            // Wait for sheet to appear
            XCTAssertTrue(app.staticTexts["Create Account"].waitForExistence(timeout: 1))
            
            let signUpButton = app.buttons["Sign Up"]
            
            // Then: Sign up button should be disabled
            XCTAssertFalse(signUpButton.isEnabled)
        }
    }
    
    /// Test: Sign Up View Sign Up Button Enabled When Fields Valid
    /// Verifies that sign up button is enabled when all fields are valid
    func testSignUpView_SignUpButton_EnabledWhenFieldsValid() throws {
        XCTContext.runActivity(named: "Test: Sign Up View Sign Up Button Enabled When Fields Valid") { _ in
            // Given: Sign up view
            app.buttons["Email"].tap() // Open sheet
            
            // Wait for sheet to appear
            XCTAssertTrue(app.staticTexts["Create Account"].waitForExistence(timeout: 1))
            
            let emailField = app.textFields["signUpEmailField"]
            let passwordField = app.secureTextFields["signUpPasswordField"]
            let confirmPasswordField = app.secureTextFields["signUpConfirmPasswordField"]
            let signUpButton = app.buttons["Sign Up"]
            
            // When: Entering matching credentials (shorter for speed)
            emailField.tap()
            emailField.typeText("a@b.c")
            
            passwordField.tap()
            passwordField.typeText("pass123")
            
            confirmPasswordField.tap()
            confirmPasswordField.typeText("pass123")
            
            // Then: Sign up button should be enabled
            XCTAssertTrue(signUpButton.isEnabled)
        }
    }
    
    /// Test: Sign Up View Shows Error When Passwords Don't Match
    /// Verifies that error message appears when passwords don't match
    func testSignUpView_ShowsError_WhenPasswordsDontMatch() throws {
        XCTContext.runActivity(named: "Test: Sign Up View Shows Error When Passwords Don't Match") { _ in
            // Given: Sign up view
            app.buttons["Email"].tap() // Open sheet
            
            // Wait for sheet to appear
            XCTAssertTrue(app.staticTexts["Create Account"].waitForExistence(timeout: 1))
            
            let passwordField = app.secureTextFields["signUpPasswordField"]
            let confirmPasswordField = app.secureTextFields["signUpConfirmPasswordField"]
            
            // When: Entering non-matching passwords (shorter for speed)
            passwordField.tap()
            passwordField.typeText("pass123")
            
            confirmPasswordField.tap()
            confirmPasswordField.typeText("diff456")
            
            // Then: Should show error message
            XCTAssertTrue(app.staticTexts["Passwords do not match"].waitForExistence(timeout: 1))
        }
    }
    
    /// Test: Sign Up View Close Button Dismisses Sheet
    /// Verifies that close button dismisses the sign up sheet
    func testSignUpView_CloseButton_DismissesSheet() throws {
        XCTContext.runActivity(named: "Test: Sign Up View Close Button Dismisses Sheet") { _ in
            // Given: Sign up view
            app.buttons["Email"].tap() // Open sheet
            
            // Wait for sheet to appear
            XCTAssertTrue(app.staticTexts["Create Account"].waitForExistence(timeout: 1))
            
            // When: Tapping close button  
            let closeButton = app.buttons["xmark"].firstMatch
            XCTAssertTrue(closeButton.waitForExistence(timeout: 1))
            closeButton.tap()
            
            // Then: Should return to login view
            XCTAssertTrue(app.staticTexts["Welcome Back"].waitForExistence(timeout: 1))
        }
    }
    
    // MARK: - Forgot Password View Tests
    
    /// Test: Forgot Password View Displays Correctly
    /// Verifies that all forgot password screen elements are visible
    func testForgotPasswordView_DisplaysCorrectly() throws {
        XCTContext.runActivity(named: "Test: Forgot Password View Displays Correctly") { _ in
            // Given: Login view
            let forgotPasswordButton = app.buttons["Forgot Password?"]
            
            // When: Opening forgot password sheet
            forgotPasswordButton.tap()
            
            // Wait for sheet to appear
            XCTAssertTrue(app.staticTexts["Reset Password"].waitForExistence(timeout: 1))
            
            // Then: Should show all required elements
            XCTAssertTrue(app.textFields["forgotPasswordEmailField"].exists)
            XCTAssertTrue(app.buttons["Send Reset Link"].exists)
            XCTAssertTrue(app.buttons["Back to Sign In"].exists)
        }
    }
    
    /// Test: Forgot Password View Send Button Disabled When Email Empty
    /// Verifies that send button is disabled when email field is empty
    func testForgotPasswordView_SendButton_DisabledWhenEmailEmpty() throws {
        XCTContext.runActivity(named: "Test: Forgot Password View Send Button Disabled When Email Empty") { _ in
            // Given: Forgot password view with empty email
            app.buttons["Forgot Password?"].tap() // Open sheet
            
            // Wait for sheet to appear
            XCTAssertTrue(app.staticTexts["Reset Password"].waitForExistence(timeout: 1))
            
            let sendButton = app.buttons["Send Reset Link"]
            
            // Then: Send button should be disabled
            XCTAssertFalse(sendButton.isEnabled)
        }
    }
    
    /// Test: Forgot Password View Send Button Enabled When Email Filled
    /// Verifies that send button is enabled when email is provided
    func testForgotPasswordView_SendButton_EnabledWhenEmailFilled() throws {
        XCTContext.runActivity(named: "Test: Forgot Password View Send Button Enabled When Email Filled") { _ in
            // Given: Forgot password view
            app.buttons["Forgot Password?"].tap() // Open sheet
            
            // Wait for sheet to appear
            XCTAssertTrue(app.staticTexts["Reset Password"].waitForExistence(timeout: 1))
            
            let emailField = app.textFields["forgotPasswordEmailField"]
            let sendButton = app.buttons["Send Reset Link"]
            
            // When: Entering email (shorter for speed)
            emailField.tap()
            emailField.typeText("a@b.c")
            
            // Then: Send button should be enabled
            XCTAssertTrue(sendButton.isEnabled)
        }
    }
    
    /// Test: Forgot Password View Back Button Dismisses Sheet
    /// Verifies that back button dismisses the forgot password sheet
    func testForgotPasswordView_BackButton_DismissesSheet() throws {
        XCTContext.runActivity(named: "Test: Forgot Password View Back Button Dismisses Sheet") { _ in
            // Given: Forgot password view
            app.buttons["Forgot Password?"].tap() // Open sheet
            
            // Wait for sheet to appear
            XCTAssertTrue(app.staticTexts["Reset Password"].waitForExistence(timeout: 1))
            
            // When: Tapping back button
            app.buttons["Back to Sign In"].tap()
            
            // Then: Should return to login view
            XCTAssertTrue(app.staticTexts["Welcome Back"].waitForExistence(timeout: 1))
        }
    }
    
    // MARK: - Navigation Tests
    
    /// Test: Navigation Between Auth Screens
    /// Verifies that users can navigate between all authentication screens
    func testNavigation_BetweenAuthScreens() throws {
        XCTContext.runActivity(named: "Test: Navigation Between Auth Screens") { _ in
            // Given: Login view
            XCTAssertTrue(app.staticTexts["Welcome Back"].exists)
            
            // When: Navigating to sign up
            app.buttons["Email"].tap()
            XCTAssertTrue(app.staticTexts["Create Account"].waitForExistence(timeout: 1))
            
            // When: Closing sign up
            let closeButton = app.buttons["xmark"].firstMatch
            XCTAssertTrue(closeButton.waitForExistence(timeout: 1))
            closeButton.tap()
            XCTAssertTrue(app.staticTexts["Welcome Back"].waitForExistence(timeout: 1))
            
            // When: Navigating to forgot password
            app.buttons["Forgot Password?"].tap()
            XCTAssertTrue(app.staticTexts["Reset Password"].waitForExistence(timeout: 1))
            
            // When: Going back to login
            app.buttons["Back to Sign In"].tap()
            XCTAssertTrue(app.staticTexts["Welcome Back"].waitForExistence(timeout: 1))
        }
    }
    
    // MARK: - Performance Tests
    
    /// Test: Login View Launch Performance
    /// Measures app launch performance to login view
    func testLoginView_LaunchPerformance() throws {
        XCTContext.runActivity(named: "Test: Login View Launch Performance") { _ in
            // Measure app launch to login view performance
            // Using single iteration to avoid slowing down test suite
            let options = XCTMeasureOptions()
            options.iterationCount = 1
            
            measure(metrics: [XCTApplicationLaunchMetric()], options: options) {
                let app = XCUIApplication()
                app.launchArguments = ["UI-Testing"]
                app.launch()
            }
        }
    }
}

