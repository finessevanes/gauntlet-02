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
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Login View Tests
    
    func testLoginView_DisplaysCorrectly() throws {
        // Given: App launches
        // When: Login view is displayed
        
        // Then: Should show all required elements
        XCTAssertTrue(app.staticTexts["Welcome Back"].exists)
        XCTAssertTrue(app.staticTexts["Sign in to continue"].exists)
        XCTAssertTrue(app.textFields["Enter your email"].exists)
        XCTAssertTrue(app.secureTextFields["Enter your password"].exists)
        XCTAssertTrue(app.buttons["Sign In"].exists)
        XCTAssertTrue(app.buttons["Sign in with Google"].exists)
        XCTAssertTrue(app.buttons["Forgot Password?"].exists)
        XCTAssertTrue(app.buttons["Sign Up"].exists)
    }
    
    func testLoginView_SignInButton_DisabledWhenFieldsEmpty() throws {
        // Given: Login view with empty fields
        let signInButton = app.buttons["Sign In"]
        
        // Then: Sign in button should be disabled
        XCTAssertFalse(signInButton.isEnabled)
    }
    
    func testLoginView_SignInButton_EnabledWhenFieldsFilled() throws {
        // Given: Login view
        let emailField = app.textFields["Enter your email"]
        let passwordField = app.secureTextFields["Enter your password"]
        let signInButton = app.buttons["Sign In"]
        
        // When: Entering email and password
        emailField.tap()
        emailField.typeText("test@example.com")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Then: Sign in button should be enabled
        XCTAssertTrue(signInButton.isEnabled)
    }
    
    func testLoginView_GoogleSignInButton_Exists() throws {
        // Given: Login view
        let googleButton = app.buttons["Sign in with Google"]
        
        // Then: Google sign-in button should exist and be enabled
        XCTAssertTrue(googleButton.exists)
        XCTAssertTrue(googleButton.isEnabled)
    }
    
    func testLoginView_ForgotPasswordButton_OpensSheet() throws {
        // Given: Login view
        let forgotPasswordButton = app.buttons["Forgot Password?"]
        
        // When: Tapping forgot password
        forgotPasswordButton.tap()
        
        // Then: Forgot password sheet should appear
        XCTAssertTrue(app.staticTexts["Reset Password"].waitForExistence(timeout: 2))
    }
    
    func testLoginView_SignUpButton_OpensSheet() throws {
        // Given: Login view
        let signUpButton = app.buttons["Sign Up"]
        
        // When: Tapping sign up
        signUpButton.tap()
        
        // Then: Sign up sheet should appear
        XCTAssertTrue(app.staticTexts["Create Account"].waitForExistence(timeout: 2))
    }
    
    // MARK: - Sign Up View Tests
    
    func testSignUpView_DisplaysCorrectly() throws {
        // Given: Login view
        let signUpButton = app.buttons["Sign Up"]
        
        // When: Opening sign up sheet
        signUpButton.tap()
        
        // Then: Should show all required elements
        XCTAssertTrue(app.staticTexts["Create Account"].exists)
        XCTAssertTrue(app.staticTexts["Sign up to get started"].exists)
        XCTAssertTrue(app.textFields["Enter your email"].exists)
        XCTAssertTrue(app.secureTextFields["Enter your password"].exists)
        XCTAssertTrue(app.secureTextFields["Confirm your password"].exists)
        XCTAssertTrue(app.buttons["Sign Up"].exists)
        XCTAssertTrue(app.buttons["Sign up with Google"].exists)
    }
    
    func testSignUpView_SignUpButton_DisabledWhenFieldsEmpty() throws {
        // Given: Sign up view with empty fields
        app.buttons["Sign Up"].tap() // Open sheet
        let signUpButton = app.buttons["Sign Up"]
        
        // Then: Sign up button should be disabled
        XCTAssertFalse(signUpButton.isEnabled)
    }
    
    func testSignUpView_SignUpButton_EnabledWhenFieldsValid() throws {
        // Given: Sign up view
        app.buttons["Sign Up"].tap() // Open sheet
        
        let emailField = app.textFields["Enter your email"]
        let passwordField = app.secureTextFields["Enter your password"]
        let confirmPasswordField = app.secureTextFields["Confirm your password"]
        let signUpButton = app.buttons["Sign Up"]
        
        // When: Entering matching credentials
        emailField.tap()
        emailField.typeText("newuser@example.com")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        confirmPasswordField.tap()
        confirmPasswordField.typeText("password123")
        
        // Then: Sign up button should be enabled
        XCTAssertTrue(signUpButton.isEnabled)
    }
    
    func testSignUpView_ShowsError_WhenPasswordsDontMatch() throws {
        // Given: Sign up view
        app.buttons["Sign Up"].tap() // Open sheet
        
        let passwordField = app.secureTextFields["Enter your password"]
        let confirmPasswordField = app.secureTextFields["Confirm your password"]
        
        // When: Entering non-matching passwords
        passwordField.tap()
        passwordField.typeText("password123")
        
        confirmPasswordField.tap()
        confirmPasswordField.typeText("different456")
        
        // Then: Should show error message
        XCTAssertTrue(app.staticTexts["Passwords do not match"].exists)
    }
    
    func testSignUpView_CloseButton_DismissesSheet() throws {
        // Given: Sign up view
        app.buttons["Sign Up"].tap() // Open sheet
        
        // When: Tapping close button
        app.buttons.matching(identifier: "xmark").element.tap()
        
        // Then: Should return to login view
        XCTAssertTrue(app.staticTexts["Welcome Back"].waitForExistence(timeout: 2))
    }
    
    // MARK: - Forgot Password View Tests
    
    func testForgotPasswordView_DisplaysCorrectly() throws {
        // Given: Login view
        let forgotPasswordButton = app.buttons["Forgot Password?"]
        
        // When: Opening forgot password sheet
        forgotPasswordButton.tap()
        
        // Then: Should show all required elements
        XCTAssertTrue(app.staticTexts["Reset Password"].exists)
        XCTAssertTrue(app.textFields["Enter your email"].exists)
        XCTAssertTrue(app.buttons["Send Reset Link"].exists)
        XCTAssertTrue(app.buttons["Back to Sign In"].exists)
    }
    
    func testForgotPasswordView_SendButton_DisabledWhenEmailEmpty() throws {
        // Given: Forgot password view with empty email
        app.buttons["Forgot Password?"].tap() // Open sheet
        let sendButton = app.buttons["Send Reset Link"]
        
        // Then: Send button should be disabled
        XCTAssertFalse(sendButton.isEnabled)
    }
    
    func testForgotPasswordView_SendButton_EnabledWhenEmailFilled() throws {
        // Given: Forgot password view
        app.buttons["Forgot Password?"].tap() // Open sheet
        
        let emailField = app.textFields["Enter your email"]
        let sendButton = app.buttons["Send Reset Link"]
        
        // When: Entering email
        emailField.tap()
        emailField.typeText("test@example.com")
        
        // Then: Send button should be enabled
        XCTAssertTrue(sendButton.isEnabled)
    }
    
    func testForgotPasswordView_BackButton_DismissesSheet() throws {
        // Given: Forgot password view
        app.buttons["Forgot Password?"].tap() // Open sheet
        
        // When: Tapping back button
        app.buttons["Back to Sign In"].tap()
        
        // Then: Should return to login view
        XCTAssertTrue(app.staticTexts["Welcome Back"].waitForExistence(timeout: 2))
    }
    
    // MARK: - Navigation Tests
    
    func testNavigation_BetweenAuthScreens() throws {
        // Given: Login view
        XCTAssertTrue(app.staticTexts["Welcome Back"].exists)
        
        // When: Navigating to sign up
        app.buttons["Sign Up"].tap()
        XCTAssertTrue(app.staticTexts["Create Account"].waitForExistence(timeout: 2))
        
        // When: Closing sign up
        app.buttons.matching(identifier: "xmark").element.tap()
        XCTAssertTrue(app.staticTexts["Welcome Back"].waitForExistence(timeout: 2))
        
        // When: Navigating to forgot password
        app.buttons["Forgot Password?"].tap()
        XCTAssertTrue(app.staticTexts["Reset Password"].waitForExistence(timeout: 2))
        
        // When: Going back to login
        app.buttons["Back to Sign In"].tap()
        XCTAssertTrue(app.staticTexts["Welcome Back"].waitForExistence(timeout: 2))
    }
    
    // MARK: - Performance Tests
    
    func testLoginView_LaunchPerformance() throws {
        // Measure app launch to login view performance
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["UI-Testing"]
            app.launch()
        }
    }
}

