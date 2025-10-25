//
//  ProfileCategory.swift
//  Psst
//
//  Created by Caleb (Coder Agent) on 10/24/25.
//  PR #007: Contextual Intelligence (Auto Client Profiles)
//

import Foundation

/// Categories for organizing client profile information
enum ProfileCategory: String, Codable, CaseIterable {
    case injuries
    case goals
    case equipment
    case preferences
    case travel
    case stressFactors

    /// Display name for UI
    var displayName: String {
        switch self {
        case .injuries: return "Injuries"
        case .goals: return "Goals"
        case .equipment: return "Equipment"
        case .preferences: return "Preferences"
        case .travel: return "Travel"
        case .stressFactors: return "Stress Factors"
        }
    }

    /// Emoji icon for category
    var icon: String {
        switch self {
        case .injuries: return "🩹"
        case .goals: return "🏋️"
        case .equipment: return "🛠️"
        case .preferences: return "⚙️"
        case .travel: return "✈️"
        case .stressFactors: return "😰"
        }
    }
}
