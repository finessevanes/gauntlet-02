//
//  ReminderSuggestion.swift
//  Psst
//
//  Created by Caleb (AI Agent) on PR #006
//  Contextual AI Actions - Reminder suggestion model for Set Reminder action
//

import Foundation

/// AI-generated suggestion for creating a reminder from a message
struct ReminderSuggestion: Codable {
    let text: String
    let suggestedDate: Date
    let extractedInfo: [String: String] // e.g., ["client": "John", "topic": "knee pain"]
}

