//
//  GoogleCalendarSyncService.swift
//  Psst
//
//  Created for PR #010C: Google Calendar Integration (One-Way Sync)
//  Service for managing Google Calendar OAuth and event sync
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import AuthenticationServices

/// Service for syncing calendar events to Google Calendar (one-way: Psst → Google)
/// Handles OAuth 2.0 authentication, token management, and event sync operations
class GoogleCalendarSyncService: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = GoogleCalendarSyncService()

    // MARK: - Published Properties

    @Published var isConnected: Bool = false
    @Published var connectedEmail: String?
    @Published var syncStatus: SyncStatus = .idle

    // MARK: - Private Properties

    private let db = Firestore.firestore()
    private let usersCollection = "users"

    // Google Calendar API OAuth Configuration
    // OAuth credentials are stored securely in Secrets.plist (excluded from git)
    private let clientId = SecretsManager.SecretKey.googleClientId.value
    private let clientSecret = SecretsManager.SecretKey.googleClientSecret.value
    private let redirectUri = SecretsManager.SecretKey.googleRedirectUri.value
    private let scope = SecretsManager.SecretKey.googleScope.value

    // Google Calendar API endpoints
    private let calendarApiBaseUrl = "https://www.googleapis.com/calendar/v3"
    private let authorizationEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
    private let tokenEndpoint = "https://oauth2.googleapis.com/token"

    // OAuth session
    private var authSession: ASWebAuthenticationSession?

    // MARK: - Initialization

    private override init() {
        super.init()
        Task {
            await checkConnectionStatus()
        }
    }

    // MARK: - OAuth Methods

    /// Connect Google Calendar via OAuth 2.0
    /// - Returns: True if connection successful
    /// - Throws: GoogleCalendarError
    func connectGoogleCalendar() async throws -> Bool {
        guard let currentUser = Auth.auth().currentUser else {
            throw GoogleCalendarError.notConnected
        }

        // Build OAuth authorization URL
        var components = URLComponents(string: authorizationEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "access_type", value: "offline"),  // Get refresh token
            URLQueryItem(name: "prompt", value: "consent")  // Force consent screen for refresh token
        ]

        guard let authUrl = components.url else {
            throw GoogleCalendarError.authFailed("Invalid authorization URL")
        }

        // Start OAuth flow using ASWebAuthenticationSession
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: GoogleCalendarError.authFailed("Service deallocated"))
                    return
                }

                // Extract callback scheme from redirect URI (e.g., "com.googleusercontent.apps.123-abc:/oauth2callback" → "com.googleusercontent.apps.123-abc")
                let callbackScheme = self.redirectUri.components(separatedBy: ":").first ?? "com.psst.app"

                let session = ASWebAuthenticationSession(
                    url: authUrl,
                    callbackURLScheme: callbackScheme
                ) { callbackURL, error in
                    if let error = error {
                        continuation.resume(throwing: GoogleCalendarError.authFailed(error.localizedDescription))
                        return
                    }

                    guard let callbackURL = callbackURL,
                          let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                          let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                        continuation.resume(throwing: GoogleCalendarError.authFailed("No authorization code received"))
                        return
                    }

                    // Exchange authorization code for tokens
                    Task {
                        do {
                            let tokens = try await self.exchangeCodeForTokens(code: code)

                            // Store refresh token in Firestore
                            try await self.storeRefreshToken(
                                userId: currentUser.uid,
                                refreshToken: tokens.refreshToken,
                                email: tokens.email
                            )

                            await MainActor.run {
                                self.isConnected = true
                                self.connectedEmail = tokens.email
                            }

                            // Trigger backfill of existing events (after connection is fully established)
                            Task {
                                // Small delay to ensure Firestore write is complete
                                try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
                                try? await self.backfillExistingEvents(trainerId: currentUser.uid)
                            }

                            continuation.resume(returning: true)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }

                // Configure session to not cache credentials
                session.presentationContextProvider = self
                session.prefersEphemeralWebBrowserSession = true  // Don't cache cookies/credentials

                self.authSession = session
                self.authSession?.start()
            }
        }
    }

    /// Disconnect Google Calendar (revoke OAuth token)
    /// - Throws: GoogleCalendarError
    func disconnectGoogleCalendar() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw GoogleCalendarError.unauthorized
        }

        // Get refresh token (read nested structure properly)
        let userDoc = try await db.collection(usersCollection).document(currentUser.uid).getDocument()
        guard let integrations = userDoc.data()?["integrations"] as? [String: Any],
              let googleCalendar = integrations["googleCalendar"] as? [String: Any],
              let refreshToken = googleCalendar["refreshToken"] as? String else {
            throw GoogleCalendarError.notConnected
        }

        // Revoke token with Google
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/revoke")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "token=\(refreshToken)".data(using: .utf8)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GoogleCalendarError.networkError
        }

        // Clear from Firestore
        try await db.collection(usersCollection).document(currentUser.uid).updateData([
            "integrations.googleCalendar": FieldValue.delete()
        ])

        // Cancel any active auth session
        await MainActor.run {
            self.authSession?.cancel()
            self.authSession = nil
            self.isConnected = false
            self.connectedEmail = nil
        }
    }

    /// Check connection status
    /// - Returns: True if connected
    func checkConnectionStatus() async -> Bool {
        guard let currentUser = Auth.auth().currentUser else {
            await MainActor.run {
                self.isConnected = false
                self.connectedEmail = nil
            }
            return false
        }

        do {
            let userDoc = try await db.collection(usersCollection).document(currentUser.uid).getDocument()

            // Read nested structure properly
            let integrations = userDoc.data()?["integrations"] as? [String: Any]
            let googleCalendar = integrations?["googleCalendar"] as? [String: Any]
            let hasRefreshToken = googleCalendar?["refreshToken"] != nil
            let email = googleCalendar?["connectedEmail"] as? String

            await MainActor.run {
                self.isConnected = hasRefreshToken
                self.connectedEmail = email
            }

            return hasRefreshToken
        } catch {
            await MainActor.run {
                self.isConnected = false
                self.connectedEmail = nil
            }
            return false
        }
    }

    // MARK: - Sync Methods

    /// Sync event to Google Calendar (create or update)
    /// - Parameter event: CalendarEvent to sync
    /// - Returns: Google Calendar event ID
    /// - Throws: GoogleCalendarError
    func syncEventToGoogle(event: CalendarEvent) async throws -> String {
        await MainActor.run { self.syncStatus = .syncing }

        // Get access token
        let accessToken = try await getAccessToken()

        // Convert CalendarEvent to Google Calendar format
        let googleEvent = convertToGoogleCalendarFormat(event: event)

        let endpoint: String
        let method: String

        if let googleEventId = event.googleCalendarEventId {
            // Update existing event
            endpoint = "\(calendarApiBaseUrl)/calendars/primary/events/\(googleEventId)"
            method = "PUT"
        } else {
            // Create new event
            endpoint = "\(calendarApiBaseUrl)/calendars/primary/events"
            method = "POST"
        }

        // Make API request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: googleEvent)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            await MainActor.run { self.syncStatus = .failed }
            throw GoogleCalendarError.networkError
        }

        // Handle rate limiting
        if httpResponse.statusCode == 429 {
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap { Int($0) } ?? 60
            await MainActor.run { self.syncStatus = .failed }
            throw GoogleCalendarError.rateLimitExceeded(retryAfter: retryAfter)
        }

        // Handle unauthorized (token expired)
        if httpResponse.statusCode == 401 {
            // Token refresh will be attempted automatically by getAccessToken()
            await MainActor.run { self.syncStatus = .failed }
            throw GoogleCalendarError.tokenRefreshFailed
        }

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            await MainActor.run { self.syncStatus = .failed }
            throw GoogleCalendarError.syncFailed("HTTP \(httpResponse.statusCode)")
        }

        // Parse response to get event ID
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let eventId = json?["id"] as? String else {
            await MainActor.run { self.syncStatus = .failed }
            throw GoogleCalendarError.syncFailed("No event ID in response")
        }

        await MainActor.run { self.syncStatus = .synced }
        return eventId
    }

    /// Delete event from Google Calendar
    /// - Parameter googleEventId: Google Calendar event ID
    /// - Throws: GoogleCalendarError
    func deleteEventFromGoogle(googleEventId: String) async throws {
        // Get access token
        let accessToken = try await getAccessToken()

        // Make delete request
        let endpoint = "\(calendarApiBaseUrl)/calendars/primary/events/\(googleEventId)"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleCalendarError.networkError
        }

        // 204 = success, 404 = already deleted (graceful)
        guard httpResponse.statusCode == 204 || httpResponse.statusCode == 404 else {
            throw GoogleCalendarError.syncFailed("HTTP \(httpResponse.statusCode)")
        }
    }

    /// Retry sync with exponential backoff
    /// - Parameters:
    ///   - event: CalendarEvent to sync
    ///   - attempt: Current attempt number (1-based)
    /// - Returns: Google Calendar event ID
    /// - Throws: GoogleCalendarError after max attempts
    func retrySyncWithBackoff(event: CalendarEvent, attempt: Int = 1) async throws -> String {
        let maxAttempts = 3
        let delays: [TimeInterval] = [5, 10, 30]  // seconds

        do {
            return try await syncEventToGoogle(event: event)
        } catch {
            guard attempt < maxAttempts else {
                throw error  // Max attempts reached
            }

            // Wait with exponential backoff
            try await Task.sleep(nanoseconds: UInt64(delays[attempt - 1] * 1_000_000_000))

            // Retry
            return try await retrySyncWithBackoff(event: event, attempt: attempt + 1)
        }
    }

    /// Backfill existing events to Google Calendar (on first connection)
    /// - Parameter trainerId: Trainer's user ID
    /// - Throws: GoogleCalendarError
    func backfillExistingEvents(trainerId: String) async throws {
        // Get events from last 30 days that haven't been synced
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

        let snapshot = try await db.collection("calendar")
            .whereField("trainerId", isEqualTo: trainerId)
            .whereField("startTime", isGreaterThan: Timestamp(date: thirtyDaysAgo))
            .getDocuments()

        let events = snapshot.documents.compactMap { CalendarEvent(document: $0) }
            .filter { $0.googleCalendarEventId == nil }  // Only un-synced events

        // Sync each event (sequentially to avoid rate limits)
        for event in events {
            do {
                let googleEventId = try await syncEventToGoogle(event: event)

                // Update Firestore with Google event ID
                try await db.collection("calendar").document(event.id).updateData([
                    "googleCalendarEventId": googleEventId,
                    "syncedAt": FieldValue.serverTimestamp()
                ])
            } catch {
                // Continue with next event on failure
            }
        }
    }

    // MARK: - Private Helper Methods

    /// Exchange authorization code for access and refresh tokens
    private func exchangeCodeForTokens(code: String) async throws -> (refreshToken: String, email: String) {
        var request = URLRequest(url: URL(string: tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // iOS clients don't use client_secret - omit it from the request
        let body = [
            "code": code,
            "client_id": clientId,
            "redirect_uri": redirectUri,
            "grant_type": "authorization_code"
        ]

        request.httpBody = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleCalendarError.authFailed("No HTTP response")
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GoogleCalendarError.authFailed("Token exchange failed: \(errorMessage)")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let refreshToken = json?["refresh_token"] as? String else {
            throw GoogleCalendarError.authFailed("No refresh token received")
        }

        // Get access token to fetch user email
        guard let accessToken = json?["access_token"] as? String else {
            throw GoogleCalendarError.authFailed("No access token received")
        }

        // Fetch user email from Google userinfo API
        let email = try await fetchUserEmail(accessToken: accessToken)

        return (refreshToken, email)
    }

    /// Fetch user email from Google userinfo API
    private func fetchUserEmail(accessToken: String) async throws -> String {
        let userinfoUrl = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!
        var request = URLRequest(url: userinfoUrl)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            return "user@gmail.com"  // Fallback
        }

        guard httpResponse.statusCode == 200 else {
            return "user@gmail.com"  // Fallback
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let email = json?["email"] as? String ?? "user@gmail.com"

        return email
    }

    /// Store refresh token in Firestore
    private func storeRefreshToken(userId: String, refreshToken: String, email: String) async throws {
        try await db.collection(usersCollection).document(userId).setData([
            "integrations": [
                "googleCalendar": [
                    "refreshToken": refreshToken,
                    "connectedAt": FieldValue.serverTimestamp(),
                    "connectedEmail": email
                ]
            ]
        ], merge: true)
    }

    /// Get valid access token (refresh if needed)
    private func getAccessToken() async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            throw GoogleCalendarError.unauthorized
        }

        // Get refresh token from Firestore (must read nested structure properly)
        let userDoc = try await db.collection(usersCollection).document(currentUser.uid).getDocument()
        guard let integrations = userDoc.data()?["integrations"] as? [String: Any],
              let googleCalendar = integrations["googleCalendar"] as? [String: Any],
              let refreshToken = googleCalendar["refreshToken"] as? String else {
            throw GoogleCalendarError.notConnected
        }

        // Refresh access token
        return try await refreshAccessToken(refreshToken: refreshToken)
    }

    /// Refresh access token using refresh token
    private func refreshAccessToken(refreshToken: String) async throws -> String {
        var request = URLRequest(url: URL(string: tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "refresh_token": refreshToken,
            "client_id": clientId,
            "client_secret": clientSecret,
            "grant_type": "refresh_token"
        ]

        request.httpBody = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GoogleCalendarError.tokenRefreshFailed
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let accessToken = json?["access_token"] as? String else {
            throw GoogleCalendarError.tokenRefreshFailed
        }

        return accessToken
    }

    /// Convert CalendarEvent to Google Calendar API format
    private func convertToGoogleCalendarFormat(event: CalendarEvent) -> [String: Any] {
        let dateFormatter = ISO8601DateFormatter()

        var googleEvent: [String: Any] = [
            "summary": event.title,
            "start": [
                "dateTime": dateFormatter.string(from: event.startTime),
                "timeZone": TimeZone.current.identifier
            ],
            "end": [
                "dateTime": dateFormatter.string(from: event.endTime),
                "timeZone": TimeZone.current.identifier
            ]
        ]

        // Add optional fields
        if let location = event.location {
            googleEvent["location"] = location
        }

        if let notes = event.notes {
            googleEvent["description"] = notes
        }

        return googleEvent
    }

    // MARK: - Error Types

    enum GoogleCalendarError: LocalizedError {
        case notConnected
        case authFailed(String)
        case permissionDenied
        case syncFailed(String)
        case rateLimitExceeded(retryAfter: Int)
        case tokenRefreshFailed
        case networkError
        case unauthorized

        var errorDescription: String? {
            switch self {
            case .notConnected:
                return "Google Calendar not connected. Please connect your account in Settings."
            case .authFailed(let reason):
                return "Authentication failed: \(reason)"
            case .permissionDenied:
                return "Permission denied. Please grant calendar access."
            case .syncFailed(let reason):
                return "Sync failed: \(reason)"
            case .rateLimitExceeded(let retryAfter):
                return "Too many requests. Please wait \(retryAfter) seconds."
            case .tokenRefreshFailed:
                return "Token refresh failed. Please reconnect your Google account."
            case .networkError:
                return "Network error. Please check your connection."
            case .unauthorized:
                return "You are not authorized to perform this action."
            }
        }
    }

    enum SyncStatus {
        case idle
        case syncing
        case synced
        case failed
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension GoogleCalendarSyncService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Return the window for presenting the authentication session
        return ASPresentationAnchor()
    }
}
