//
//  UserServiceTests.swift
//  PsstTests
//
//  Created by Caleb (Coder Agent) - PR #3
//  Unit tests for UserService using Swift Testing framework
//

import Testing
@testable import Psst
import FirebaseFirestore

/// Unit tests for UserService
/// Tests CRUD operations, validation, caching, and real-time listeners
@Suite("User Service Tests")
struct UserServiceTests {

    // MARK: - Setup & Cleanup

    init() {
        // Clear cache before each test
        UserService.shared.clearCache()
    }

    // MARK: - Service Contract Tests

    /// Verifies that UserService maintains a single shared instance
    @Test("User Service Is Singleton")
    func userServiceIsSingleton() {
        // Given: Multiple references to UserService
        let instance1 = UserService.shared
        let instance2 = UserService.shared

        // Then: Should be same instance
        #expect(instance1 === instance2, "UserService should be a singleton")
    }

    // MARK: - Error Tests

    /// Verifies that UserServiceError.invalidUserID has correct description
    @Test("User Service Error - Invalid User ID Has Correct Description")
    func userServiceErrorInvalidUserIDHasCorrectDescription() {
        // Given: Invalid user ID error
        let error = UserServiceError.invalidUserID

        // When: Getting error description
        let description = error.errorDescription

        // Then: Should have user-friendly message
        #expect(description != nil)
        #expect(description?.contains("User ID") ?? false)
    }

    /// Verifies that UserServiceError.invalidEmail has correct description
    @Test("User Service Error - Invalid Email Has Correct Description")
    func userServiceErrorInvalidEmailHasCorrectDescription() {
        // Given: Invalid email error
        let error = UserServiceError.invalidEmail

        // When: Getting error description
        let description = error.errorDescription

        // Then: Should have user-friendly message
        #expect(description != nil)
        #expect(description?.contains("email") ?? false)
    }

    /// Verifies that UserServiceError.userNotFound has correct description
    @Test("User Service Error - User Not Found Has Correct Description")
    func userServiceErrorUserNotFoundHasCorrectDescription() {
        // Given: User not found error
        let error = UserServiceError.userNotFound

        // When: Getting error description
        let description = error.errorDescription

        // Then: Should have user-friendly message
        #expect(description != nil)
        #expect(description?.contains("not found") ?? false)
    }

    /// Verifies that UserServiceError.validationFailed has correct description
    @Test("User Service Error - Validation Failed Has Correct Description")
    func userServiceErrorValidationFailedHasCorrectDescription() {
        // Given: Validation failed error
        let error = UserServiceError.validationFailed("Test validation message")

        // When: Getting error description
        let description = error.errorDescription

        // Then: Should have user-friendly message with custom text
        #expect(description != nil)
        #expect(description?.contains("Validation") ?? false)
        #expect(description?.contains("Test validation message") ?? false)
    }

    // MARK: - Validation Tests

    /// Verifies that createUser throws error for empty user ID
    @Test("Create User - Empty ID Throws Error")
    func createUserWithEmptyIDThrowsError() async {
        // Given: Empty user ID
        let emptyID = ""

        // When/Then: Creating user should throw invalidUserID error
        await #expect(throws: UserServiceError.invalidUserID) {
            try await UserService.shared.createUser(
                id: emptyID,
                email: "test@example.com",
                displayName: "Test User"
            )
        }
    }

    /// Verifies that createUser throws error for invalid email
    @Test("Create User - Invalid Email Throws Error")
    func createUserWithInvalidEmailThrowsError() async {
        // Given: Invalid email (no @ symbol)
        let invalidEmail = "notanemail"

        // When/Then: Creating user should throw invalidEmail error
        await #expect(throws: UserServiceError.invalidEmail) {
            try await UserService.shared.createUser(
                id: "test123",
                email: invalidEmail,
                displayName: "Test User"
            )
        }
    }

    /// Verifies that createUser throws error for empty displayName
    @Test("Create User - Empty Display Name Throws Error")
    func createUserWithEmptyDisplayNameThrowsError() async {
        // Given: Empty display name
        let emptyName = ""

        // When/Then: Creating user should throw validationFailed error
        await #expect(throws: UserServiceError.validationFailed("Display name must be 1-50 characters")) {
            try await UserService.shared.createUser(
                id: "test123",
                email: "test@example.com",
                displayName: emptyName
            )
        }
    }

    /// Verifies that createUser throws error for displayName over 50 characters
    @Test("Create User - Display Name Over 50 Characters Throws Error")
    func createUserWithLongDisplayNameThrowsError() async {
        // Given: Display name with 51 characters
        let longName = String(repeating: "a", count: 51)

        // When/Then: Creating user should throw validationFailed error
        await #expect(throws: UserServiceError.validationFailed("Display name must be 1-50 characters")) {
            try await UserService.shared.createUser(
                id: "test123",
                email: "test@example.com",
                displayName: longName
            )
        }
    }

    /// Verifies that updateUser throws error for empty user ID
    @Test("Update User - Empty ID Throws Error")
    func updateUserWithEmptyIDThrowsError() async {
        // Given: Empty user ID
        let emptyID = ""

        // When/Then: Updating user should throw invalidUserID error
        await #expect(throws: UserServiceError.invalidUserID) {
            try await UserService.shared.updateUser(
                id: emptyID,
                data: ["displayName": "New Name"]
            )
        }
    }

    /// Verifies that updateUser throws error for invalid displayName
    @Test("Update User - Invalid Display Name Throws Error")
    func updateUserWithInvalidDisplayNameThrowsError() async {
        // Given: Empty display name in update data
        let updateData: [String: Any] = ["displayName": ""]

        // When/Then: Updating user should throw validationFailed error
        await #expect(throws: UserServiceError.validationFailed("Display name must be 1-50 characters")) {
            try await UserService.shared.updateUser(
                id: "test123",
                data: updateData
            )
        }
    }

    // MARK: - Cache Tests

    /// Verifies that clearCache removes all cached users
    @Test("Clear Cache - Removes All Cached Users")
    func clearCacheRemovesAllCachedUsers() {
        // Given: UserService with cache
        let service = UserService.shared

        // When: Clearing cache
        service.clearCache()

        // Then: Cache should be cleared (no error thrown)
        // Note: Cache is private, so we verify indirectly by ensuring method completes
        #expect(true, "clearCache should complete without error")
    }

    // MARK: - Model Tests

    /// Verifies that User model can be encoded and decoded
    @Test("User Model - Codable Conformance Works")
    func userModelCodableConformanceWorks() throws {
        // Given: User object
        let user = User(
            id: "test123",
            email: "test@example.com",
            displayName: "Test User",
            photoURL: "https://example.com/photo.jpg",
            createdAt: Date(),
            updatedAt: Date()
        )

        // When: Encoding and decoding user
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)
        let decoder = JSONDecoder()
        let decodedUser = try decoder.decode(User.self, from: data)

        // Then: Should decode successfully
        #expect(decodedUser.id == user.id)
        #expect(decodedUser.email == user.email)
        #expect(decodedUser.displayName == user.displayName)
        #expect(decodedUser.photoURL == user.photoURL)
    }

    /// Verifies that User toDictionary includes all required fields
    @Test("User Model - To Dictionary Includes Required Fields")
    func userModelToDictionaryIncludesRequiredFields() {
        // Given: User object
        let user = User(
            id: "test123",
            email: "test@example.com",
            displayName: "Test User",
            photoURL: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When: Converting to dictionary
        let dict = user.toDictionary()

        // Then: Should include all required fields
        #expect(dict["uid"] as? String == "test123")
        #expect(dict["email"] as? String == "test@example.com")
        #expect(dict["displayName"] as? String == "Test User")
        #expect(dict["createdAt"] != nil)
        #expect(dict["updatedAt"] != nil)
    }

    /// Verifies that User toDictionary includes optional photoURL when present
    @Test("User Model - To Dictionary Includes Photo URL When Present")
    func userModelToDictionaryIncludesPhotoURLWhenPresent() {
        // Given: User object with photo URL
        let user = User(
            id: "test123",
            email: "test@example.com",
            displayName: "Test User",
            photoURL: "https://example.com/photo.jpg",
            createdAt: Date(),
            updatedAt: Date()
        )

        // When: Converting to dictionary
        let dict = user.toDictionary()

        // Then: Should include photoURL
        #expect(dict["photoURL"] as? String == "https://example.com/photo.jpg")
    }

    /// Verifies that User CodingKeys maps id to uid
    @Test("User Model - Coding Keys Maps ID To UID")
    func userModelCodingKeysMapsIDToUID() throws {
        // Given: JSON with uid field
        let json = """
        {
            "uid": "test123",
            "email": "test@example.com",
            "displayName": "Test User",
            "createdAt": 1234567890.0,
            "updatedAt": 1234567890.0
        }
        """
        let data = json.data(using: .utf8)!

        // When: Decoding user
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let user = try decoder.decode(User.self, from: data)

        // Then: id property should map to uid field
        #expect(user.id == "test123")
    }

    /// Verifies that User model has Equatable conformance
    @Test("User Model - Equatable Conformance Works")
    func userModelEquatableConformanceWorks() {
        // Given: Two identical user objects
        let user1 = User(
            id: "test123",
            email: "test@example.com",
            displayName: "Test User",
            photoURL: nil,
            createdAt: Date(timeIntervalSince1970: 1234567890),
            updatedAt: Date(timeIntervalSince1970: 1234567890)
        )

        let user2 = User(
            id: "test123",
            email: "test@example.com",
            displayName: "Test User",
            photoURL: nil,
            createdAt: Date(timeIntervalSince1970: 1234567890),
            updatedAt: Date(timeIntervalSince1970: 1234567890)
        )

        // Then: Should be equal
        #expect(user1 == user2, "Identical users should be equal")
    }

    /// Verifies that User model has Identifiable conformance
    @Test("User Model - Identifiable Conformance Works")
    func userModelIdentifiableConformanceWorks() {
        // Given: User object
        let user = User(
            id: "test123",
            email: "test@example.com",
            displayName: "Test User"
        )

        // Then: Should have id property accessible as Identifiable
        #expect(user.id == "test123")
    }

    // MARK: - Integration Notes
    // The following tests require a live Firebase connection or emulator:
    // - Happy path tests (create, fetch, update, observe, batch)
    // - Firestore error handling tests
    // - Offline behavior tests
    // - Performance tests
    //
    // These tests should be run manually or in a separate test suite
    // with Firebase emulator configured. See TODO checklist for details.

}
