//
//  ProfileItem.swift
//  Psst
//
//  Created by Caleb (Coder Agent) on 10/24/25.
//  PR #007: Contextual Intelligence (Auto Client Profiles)
//

import Foundation
import FirebaseFirestore

/// Individual profile item extracted from conversations or manually added
struct ProfileItem: Codable, Identifiable, Equatable {
    let id: String
    let text: String
    let category: ProfileCategory
    let timestamp: Date
    let sourceMessageId: String
    let sourceChatId: String
    let confidenceScore: Double // 0.0-1.0
    let isManuallyEdited: Bool
    let editedAt: Date?
    let createdBy: ProfileItemSource

    /// Initializer for new profile items
    init(
        id: String = UUID().uuidString,
        text: String,
        category: ProfileCategory,
        timestamp: Date = Date(),
        sourceMessageId: String,
        sourceChatId: String,
        confidenceScore: Double = 1.0,
        isManuallyEdited: Bool = false,
        editedAt: Date? = nil,
        createdBy: ProfileItemSource
    ) {
        self.id = id
        self.text = text
        self.category = category
        self.timestamp = timestamp
        self.sourceMessageId = sourceMessageId
        self.sourceChatId = sourceChatId
        self.confidenceScore = confidenceScore
        self.isManuallyEdited = isManuallyEdited
        self.editedAt = editedAt
        self.createdBy = createdBy
    }

    /// Confidence level for AI extractions
    var confidenceLevel: ConfidenceLevel {
        if confidenceScore >= 0.8 {
            return .high
        } else if confidenceScore >= 0.5 {
            return .medium
        } else {
            return .low
        }
    }

    /// Relative time string ("2 weeks ago", "3 days ago")
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

/// Confidence level for AI-extracted profile items
enum ConfidenceLevel: String {
    case high
    case medium
    case low

    /// Display color for confidence badge
    var color: String {
        switch self {
        case .high: return "green"
        case .medium: return "orange"
        case .low: return "red"
        }
    }

    /// Display label
    var displayName: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
}

/// Extension for Firestore conversion
extension ProfileItem {
    /// Convert to Firestore dictionary
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "text": text,
            "category": category.rawValue,
            "timestamp": Timestamp(date: timestamp),
            "sourceMessageId": sourceMessageId,
            "sourceChatId": sourceChatId,
            "confidenceScore": confidenceScore,
            "isManuallyEdited": isManuallyEdited,
            "createdBy": createdBy.rawValue
        ]

        if let editedAt = editedAt {
            data["editedAt"] = Timestamp(date: editedAt)
        }

        return data
    }

    /// Create from Firestore dictionary
    static func fromFirestore(_ data: [String: Any]) throws -> ProfileItem {
        guard let id = data["id"] as? String,
              let text = data["text"] as? String,
              let categoryRaw = data["category"] as? String,
              let category = ProfileCategory(rawValue: categoryRaw),
              let timestampValue = data["timestamp"] as? Timestamp,
              let sourceMessageId = data["sourceMessageId"] as? String,
              let sourceChatId = data["sourceChatId"] as? String,
              let confidenceScore = data["confidenceScore"] as? Double,
              let isManuallyEdited = data["isManuallyEdited"] as? Bool,
              let createdByRaw = data["createdBy"] as? String,
              let createdBy = ProfileItemSource(rawValue: createdByRaw) else {
            throw ProfileError.invalidData("Missing or invalid profile item fields")
        }

        let editedAt: Date? = (data["editedAt"] as? Timestamp)?.dateValue()

        return ProfileItem(
            id: id,
            text: text,
            category: category,
            timestamp: timestampValue.dateValue(),
            sourceMessageId: sourceMessageId,
            sourceChatId: sourceChatId,
            confidenceScore: confidenceScore,
            isManuallyEdited: isManuallyEdited,
            editedAt: editedAt,
            createdBy: createdBy
        )
    }
}

/// Profile-related errors
enum ProfileError: LocalizedError {
    case notAuthenticated
    case notFound
    case invalidData(String)
    case extractionFailed(String)
    case updateFailed(String)
    case networkError
    case offline
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to access profiles"
        case .notFound:
            return "Client profile not found"
        case .invalidData(let reason):
            return "Invalid profile data: \(reason)"
        case .extractionFailed(let reason):
            return "Failed to extract profile info: \(reason)"
        case .updateFailed(let reason):
            return "Failed to update profile: \(reason)"
        case .networkError:
            return "Network connection error"
        case .offline:
            return "You're offline. Profile updates will sync when connected."
        case .permissionDenied:
            return "You don't have permission to access this profile"
        }
    }
}
