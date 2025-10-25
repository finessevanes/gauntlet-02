//
//  ClientProfile.swift
//  Psst
//
//  Created by Caleb (Coder Agent) on 10/24/25.
//  PR #007: Contextual Intelligence (Auto Client Profiles)
//

import Foundation
import FirebaseFirestore

/// Comprehensive client profile built from conversations
struct ClientProfile: Codable, Identifiable {
    let id: String // clientId
    let clientId: String
    let trainerId: String
    let createdAt: Date
    let updatedAt: Date

    var injuries: [ProfileItem]
    var goals: [ProfileItem]
    var equipment: [ProfileItem]
    var preferences: [ProfileItem]
    var travel: [ProfileItem]
    var stressFactors: [ProfileItem]

    let totalItems: Int
    let lastReviewedAt: Date?

    /// Initializer for new profiles
    init(
        id: String,
        clientId: String,
        trainerId: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        injuries: [ProfileItem] = [],
        goals: [ProfileItem] = [],
        equipment: [ProfileItem] = [],
        preferences: [ProfileItem] = [],
        travel: [ProfileItem] = [],
        stressFactors: [ProfileItem] = [],
        totalItems: Int = 0,
        lastReviewedAt: Date? = nil
    ) {
        self.id = id
        self.clientId = clientId
        self.trainerId = trainerId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.injuries = injuries
        self.goals = goals
        self.equipment = equipment
        self.preferences = preferences
        self.travel = travel
        self.stressFactors = stressFactors
        self.totalItems = totalItems
        self.lastReviewedAt = lastReviewedAt
    }

    /// Get all items for a specific category
    func items(for category: ProfileCategory) -> [ProfileItem] {
        switch category {
        case .injuries: return injuries
        case .goals: return goals
        case .equipment: return equipment
        case .preferences: return preferences
        case .travel: return travel
        case .stressFactors: return stressFactors
        }
    }

    /// Set items for a specific category
    mutating func setItems(_ items: [ProfileItem], for category: ProfileCategory) {
        switch category {
        case .injuries: self.injuries = items
        case .goals: self.goals = items
        case .equipment: self.equipment = items
        case .preferences: self.preferences = items
        case .travel: self.travel = items
        case .stressFactors: self.stressFactors = items
        }
    }

    /// Get the most recent items across all categories (for banner display)
    var mostRecentItems: [ProfileItem] {
        let allItems = injuries + goals + equipment + preferences + travel + stressFactors
        return allItems.sorted { $0.timestamp > $1.timestamp }
    }

    /// Get top N most recent items for condensed view
    func topItems(limit: Int = 5) -> [ProfileItem] {
        Array(mostRecentItems.prefix(limit))
    }

    /// Check if profile is empty
    var isEmpty: Bool {
        totalItems == 0
    }

    /// Get item count for a specific category
    func itemCount(for category: ProfileCategory) -> Int {
        items(for: category).count
    }
}

/// Extension for Firestore conversion
extension ClientProfile {
    /// Convert to Firestore dictionary
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "clientId": clientId,
            "trainerId": trainerId,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "injuries": injuries.map { $0.toFirestore() },
            "goals": goals.map { $0.toFirestore() },
            "equipment": equipment.map { $0.toFirestore() },
            "preferences": preferences.map { $0.toFirestore() },
            "travel": travel.map { $0.toFirestore() },
            "stressFactors": stressFactors.map { $0.toFirestore() },
            "totalItems": totalItems
        ]

        if let lastReviewedAt = lastReviewedAt {
            data["lastReviewedAt"] = Timestamp(date: lastReviewedAt)
        }

        return data
    }

    /// Create from Firestore dictionary
    static func fromFirestore(id: String, data: [String: Any]) throws -> ClientProfile {
        guard let clientId = data["clientId"] as? String,
              let trainerId = data["trainerId"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let updatedAtTimestamp = data["updatedAt"] as? Timestamp,
              let totalItems = data["totalItems"] as? Int else {
            throw ProfileError.invalidData("Missing or invalid client profile fields")
        }

        // Parse categorized arrays
        let injuries = try parseProfileItems(from: data["injuries"])
        let goals = try parseProfileItems(from: data["goals"])
        let equipment = try parseProfileItems(from: data["equipment"])
        let preferences = try parseProfileItems(from: data["preferences"])
        let travel = try parseProfileItems(from: data["travel"])
        let stressFactors = try parseProfileItems(from: data["stressFactors"])

        let lastReviewedAt: Date? = (data["lastReviewedAt"] as? Timestamp)?.dateValue()

        return ClientProfile(
            id: id,
            clientId: clientId,
            trainerId: trainerId,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue(),
            injuries: injuries,
            goals: goals,
            equipment: equipment,
            preferences: preferences,
            travel: travel,
            stressFactors: stressFactors,
            totalItems: totalItems,
            lastReviewedAt: lastReviewedAt
        )
    }

    /// Helper to parse profile items array from Firestore
    private static func parseProfileItems(from value: Any?) -> [ProfileItem] {
        guard let array = value as? [[String: Any]] else {
            return []
        }

        return array.compactMap { itemData in
            try? ProfileItem.fromFirestore(itemData)
        }
    }
}
