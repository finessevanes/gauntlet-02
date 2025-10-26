//
//  SecretsManager.swift
//  Psst
//
//  Utility for securely managing API keys and secrets from Secrets.plist
//  Prevents hardcoding sensitive credentials in source code
//

import Foundation

/// Manager for accessing sensitive API keys and secrets from Secrets.plist
/// Secrets.plist should be excluded from version control and managed per environment
struct SecretsManager {

    /// Retrieve a secret value from Secrets.plist
    /// - Parameter key: The key name in the plist file
    /// - Returns: The secret value as a String, or nil if not found
    static func getValue(for key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let secrets = NSDictionary(contentsOfFile: path) else {
            print("⚠️ [SecretsManager] Secrets.plist not found. Make sure to create it from Secrets.plist.example")
            return nil
        }

        guard let value = secrets[key] as? String else {
            print("⚠️ [SecretsManager] Key '\(key)' not found in Secrets.plist")
            return nil
        }

        return value
    }

    /// Available secret keys for type-safe access
    enum SecretKey: String {
        case googleClientId = "GOOGLE_CLIENT_ID"
        case googleClientSecret = "GOOGLE_CLIENT_SECRET"
        case googleRedirectUri = "GOOGLE_REDIRECT_URI"
        case googleScope = "GOOGLE_SCOPE"

        var value: String {
            SecretsManager.getValue(for: self.rawValue) ?? ""
        }
    }
}
