//
//  RelatedMessage.swift
//  Psst
//
//  Created by Caleb (AI Agent) on PR #006
//  Contextual AI Actions - Related message representation for Surface Context action
//

import Foundation

/// Represents a related message found via semantic search
struct RelatedMessage: Identifiable, Codable {
    let id: String
    let messageID: String
    let text: String
    let senderName: String
    let timestamp: Date
    let relevanceScore: Double // 0.0 - 1.0 (higher = more relevant)

    // MARK: - Relevance Thresholds

    private static let highRelevanceThreshold = 0.9
    private static let mediumRelevanceThreshold = 0.8
}

// MARK: - UI Helpers

import SwiftUI

extension RelatedMessage {
    /// Color indicating the relevance level of this message
    var relevanceColor: Color {
        switch relevanceScore {
        case Self.highRelevanceThreshold...:
            return .green
        case Self.mediumRelevanceThreshold...:
            return .orange
        default:
            return .gray
        }
    }
}

