import Foundation

/*
 Configuration Template
 
 This is a template file showing how to manage API keys and configuration in Swift.
 Similar to .env files in web development, but for iOS.
 
 TO SET UP:
 1. Copy this file: Config.example.swift → Config.swift
 2. Fill in your actual API keys and secrets
 3. Add Config.swift to .gitignore (already done)
 4. NEVER commit Config.swift to git!
 
 USAGE IN CODE:
 ```swift
 // Access configuration values
 let apiKey = Config.shared.openAIApiKey
 let baseURL = Config.shared.apiBaseURL
 ```
 
 WHY THIS PATTERN?
 - Keeps secrets out of git
 - Easy for new developers to set up
 - Type-safe configuration
 - Centralized config management
 */

class Config {
    static let shared = Config()
    
    private init() {}
    
    // MARK: - API Keys
    
    /// OpenAI API Key (if using AI features)
    /// Get from: https://platform.openai.com/api-keys
    let openAIApiKey: String = "YOUR_OPENAI_API_KEY_HERE"
    
    /// Example: Third-party service API key
    let exampleServiceKey: String = "YOUR_SERVICE_KEY_HERE"
    
    // MARK: - API Endpoints
    
    /// Base URL for your backend API
    let apiBaseURL: String = "https://your-api.example.com"
    
    /// Alternative: Use different URLs for dev/staging/prod
    var environment: Environment = .development
    
    enum Environment {
        case development
        case staging
        case production
        
        var baseURL: String {
            switch self {
            case .development:
                return "http://localhost:3000"
            case .staging:
                return "https://staging-api.example.com"
            case .production:
                return "https://api.example.com"
            }
        }
    }
    
    // MARK: - Feature Flags
    
    /// Enable/disable features in development
    let enableBetaFeatures: Bool = false
    let enableDebugLogging: Bool = true
    
    // MARK: - App Configuration
    
    /// App version from Info.plist
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    /// Build number from Info.plist
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    /// Bundle identifier
    var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.example.app"
    }
}

// MARK: - Alternative: Info.plist Based Configuration

/*
 You can also store configuration in Info.plist:
 
 1. Add to Info.plist:
    <key>API_KEY</key>
    <string>$(API_KEY)</string>
 
 2. Set in Xcode build settings or .xcconfig file
 
 3. Access in Swift:
    let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String
 
 Benefits:
 - Per-target configuration (Debug/Release)
 - Xcode manages the values
 - Good for CI/CD pipelines
 */

// MARK: - Alternative: Environment Variables

/*
 For CI/CD or testing, you can use environment variables:
 
 ```swift
 let apiKey = ProcessInfo.processInfo.environment["API_KEY"] ?? "default_key"
 ```
 
 Set in Xcode:
 Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables
 */

