//
//  SchedulingResult.swift
//  Psst
//
//  Created for PR #010B: AI Scheduling + Conflict Detection
//  Result type for AI scheduling operations
//

import Foundation

/// Result of AI scheduling attempt with conflict detection
enum SchedulingResult {
    /// Event successfully created
    case success(CalendarEvent)

    /// Conflict detected with existing event, suggestions provided
    case conflict(existing: CalendarEvent, suggestions: [Date])

    /// Client name not found in contacts
    case clientNotFound(name: String)

    /// Multiple clients match the name (ambiguous)
    case clientAmbiguous(matches: [Contact])
}
