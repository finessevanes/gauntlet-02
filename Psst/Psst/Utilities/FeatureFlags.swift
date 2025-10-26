//
//  FeatureFlags.swift
//  Psst
//
//  Created for PR #009: Trainer-Client Relationship System
//  Feature flag system using Firebase Remote Config
//

import Foundation
import FirebaseRemoteConfig

/// Feature flags for gradual feature rollouts using Firebase Remote Config
/// Allows instant rollback without code deployment
struct FeatureFlags {

    /// Enable trainer-client relationship validation in ChatService
    /// When disabled: Old behavior (everyone can message everyone)
    /// When enabled: Validates relationship exists before allowing chat creation
    /// Default: false (deploy with flag disabled, enable gradually)
    static var enableRelationshipValidation: Bool {
        let remoteConfig = RemoteConfig.remoteConfig()
        return remoteConfig.configValue(forKey: "enable_relationship_validation").boolValue
    }

    // MARK: - Remote Config Setup

    /// Configures Remote Config settings (called on app launch)
    /// - Parameter isDevelopment: Set to true for faster fetch intervals in development
    static func configure(isDevelopment: Bool = false) {
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()

        // Development: fetch every time (0 seconds)
        // Production: fetch every hour (3600 seconds)
        settings.minimumFetchInterval = isDevelopment ? 0 : 3600

        remoteConfig.configSettings = settings

        // Set default values (used before first fetch completes)
        remoteConfig.setDefaults([
            "enable_relationship_validation": NSNumber(value: false)
        ])

        Log.i("FeatureFlags", "Remote Config configured (isDevelopment: \(isDevelopment))")
    }

    /// Fetches latest Remote Config values from Firebase
    /// Call this on app launch after configure()
    static func fetchAndActivate() async throws {
        let remoteConfig = RemoteConfig.remoteConfig()

        let status = try await remoteConfig.fetch()

        if status == .success {
            try await remoteConfig.activate()
            Log.i("FeatureFlags", "Remote Config fetched and activated successfully")
        } else {
            Log.w("FeatureFlags", "Remote Config fetch failed with status: \(status.rawValue)")
        }
    }

    /// Fetches Remote Config with completion handler (for non-async contexts)
    static func fetchAndActivate(completion: @escaping (Bool) -> Void) {
        let remoteConfig = RemoteConfig.remoteConfig()

        remoteConfig.fetch { status, error in
            if let error = error {
                Log.e("FeatureFlags", "Remote Config fetch error: \(error.localizedDescription)")
                completion(false)
                return
            }

            if status == .success {
                remoteConfig.activate { changed, error in
                    if let error = error {
                        Log.e("FeatureFlags", "Remote Config activate error: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        Log.i("FeatureFlags", "Remote Config activated (changed: \(changed))")
                        completion(true)
                    }
                }
            } else {
                Log.w("FeatureFlags", "Remote Config fetch failed")
                completion(false)
            }
        }
    }
}

