//
//  KeywordDetector.swift
//  Psst
//
//  Centralized keyword detection for AI contextual actions
//  Refactored from MockAIService to eliminate duplication
//

import Foundation

/// Represents a category of keywords with associated metadata
struct KeywordCategory {
    let keywords: [String]
    let topic: String
    let priority: Priority
    let keyPoint: String

    enum Priority: String {
        case high
        case medium
        case low
    }
}

/// Centralized keyword detection for AI mock responses
class KeywordDetector {

    // MARK: - Categories

    /// All keyword categories used for topic detection
    static let categories: [KeywordCategory] = [
        KeywordCategory(
            keywords: ["pain", "injury", "knee", "shoulder"],
            topic: "Injury management",
            priority: .high,
            keyPoint: "Discussed injury concerns and modifications needed"
        ),
        KeywordCategory(
            keywords: ["workout", "exercise", "training"],
            topic: "Workout planning",
            priority: .medium,
            keyPoint: "Reviewed workout plan and exercise progression"
        ),
        KeywordCategory(
            keywords: ["diet", "nutrition", "eating", "protein"],
            topic: "Nutrition guidance",
            priority: .medium,
            keyPoint: "Covered nutrition and dietary adjustments"
        ),
        KeywordCategory(
            keywords: ["progress", "weight", "goal"],
            topic: "Progress tracking",
            priority: .medium,
            keyPoint: "Tracked progress toward fitness goals"
        ),
        KeywordCategory(
            keywords: ["schedule", "time", "session"],
            topic: "Scheduling",
            priority: .medium,
            keyPoint: "Discussed scheduling and session availability"
        )
    ]

    // MARK: - Detection Methods

    /// Detects all matching categories in the given text
    /// - Parameter text: The text to analyze
    /// - Returns: Array of matching categories, ordered by first match
    static func detectCategories(in text: String) -> [KeywordCategory] {
        let lowercasedText = text.lowercased()

        return categories.filter { category in
            category.keywords.contains { keyword in
                lowercasedText.contains(keyword)
            }
        }
    }

    /// Detects the primary category (first match) in the given text
    /// - Parameter text: The text to analyze
    /// - Returns: The first matching category, or nil if no matches
    static func detectPrimaryCategory(in text: String) -> KeywordCategory? {
        detectCategories(in: text).first
    }

    /// Checks if text contains any keywords from a specific topic
    /// - Parameters:
    ///   - text: The text to analyze
    ///   - topic: The topic to check for
    /// - Returns: True if text contains keywords from that topic
    static func contains(text: String, topic: String) -> Bool {
        let lowercasedText = text.lowercased()

        return categories.first(where: { $0.topic == topic })?.keywords.contains { keyword in
            lowercasedText.contains(keyword)
        } ?? false
    }
}
