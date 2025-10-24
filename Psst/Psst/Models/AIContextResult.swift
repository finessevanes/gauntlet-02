//
//  AIContextResult.swift
//  Psst
//
//  Created by Caleb (AI Agent) on PR #006
//  Contextual AI Actions - Result container for AI actions
//

import Foundation

/// Result of a contextual AI action
struct AIContextResult: Identifiable, Codable {
    let id: String
    let action: String // Store as String for Codable (AIContextAction.rawValue)
    let sourceMessageID: String
    let result: AIResultContent
    let timestamp: Date
    let isLoading: Bool
    let error: String?
    
    /// Helper to get action as enum
    var actionType: AIContextAction? {
        AIContextAction(rawValue: action)
    }
}

/// Content types for AI action results
enum AIResultContent: Codable {
    case summary(text: String, keyPoints: [String])
    case relatedMessages([RelatedMessage])
    case reminder(ReminderSuggestion)
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case type
        case text
        case keyPoints
        case relatedMessages
        case reminder
    }
    
    enum ContentType: String, Codable {
        case summary
        case relatedMessages
        case reminder
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)
        
        switch type {
        case .summary:
            let text = try container.decode(String.self, forKey: .text)
            let keyPoints = try container.decode([String].self, forKey: .keyPoints)
            self = .summary(text: text, keyPoints: keyPoints)
            
        case .relatedMessages:
            let messages = try container.decode([RelatedMessage].self, forKey: .relatedMessages)
            self = .relatedMessages(messages)
            
        case .reminder:
            let suggestion = try container.decode(ReminderSuggestion.self, forKey: .reminder)
            self = .reminder(suggestion)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .summary(let text, let keyPoints):
            try container.encode(ContentType.summary, forKey: .type)
            try container.encode(text, forKey: .text)
            try container.encode(keyPoints, forKey: .keyPoints)
            
        case .relatedMessages(let messages):
            try container.encode(ContentType.relatedMessages, forKey: .type)
            try container.encode(messages, forKey: .relatedMessages)
            
        case .reminder(let suggestion):
            try container.encode(ContentType.reminder, forKey: .type)
            try container.encode(suggestion, forKey: .reminder)
        }
    }
}

