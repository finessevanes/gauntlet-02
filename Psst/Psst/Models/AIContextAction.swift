//
//  AIContextAction.swift
//  Psst
//
//  Created by Caleb (AI Agent) on PR #006
//  Contextual AI Actions - Long-Press Menu
//

import Foundation

/// AI-powered actions available via long-press gesture on messages
enum AIContextAction: String, CaseIterable, Identifiable {
    case summarize = "Summarize Conversation"
    case surfaceContext = "Surface Context"
    case setReminder = "Set Reminder"
    
    var id: String { rawValue }
    
    /// SF Symbol icon name for the action
    var icon: String {
        switch self {
        case .summarize: return "chart.bar.doc.horizontal"
        case .surfaceContext: return "magnifyingglass.circle"
        case .setReminder: return "bell.badge"
        }
    }
    
    /// Human-readable description of what the action does
    var description: String {
        switch self {
        case .summarize:
            return "Get a concise summary of this conversation"
        case .surfaceContext:
            return "Find related past conversations"
        case .setReminder:
            return "Create a follow-up reminder from this message"
        }
    }
}

