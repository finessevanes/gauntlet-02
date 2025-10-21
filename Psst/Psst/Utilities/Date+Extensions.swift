//
//  Date+Extensions.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #6
//  Date formatting utilities for relative time display
//

import Foundation

extension Date {
    /// Format date as relative time string for message timestamps
    /// Examples: "Just now", "5m ago", "2h ago", "Yesterday", "Monday", "Jan 15"
    /// - Returns: Human-readable relative time string
    func relativeTimeString() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate time difference in seconds
        let secondsAgo = now.timeIntervalSince(self)
        
        // Handle future dates (shouldn't happen, but just in case)
        if secondsAgo < 0 {
            return "Just now"
        }
        
        // Less than 1 minute: "Just now"
        if secondsAgo < 60 {
            return "Just now"
        }
        
        // Less than 1 hour: "Xm ago"
        if secondsAgo < 3600 {
            let minutes = Int(secondsAgo / 60)
            return "\(minutes)m ago"
        }
        
        // Less than 24 hours: "Xh ago"
        if secondsAgo < 86400 {
            let hours = Int(secondsAgo / 3600)
            return "\(hours)h ago"
        }
        
        // Check if yesterday
        if calendar.isDateInYesterday(self) {
            return "Yesterday"
        }
        
        // Less than 7 days: Day name (e.g., "Monday")
        if secondsAgo < 604800 {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE"
            return dateFormatter.string(from: self)
        }
        
        // Older than 7 days: Date format (e.g., "Jan 15")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        return dateFormatter.string(from: self)
    }
}

