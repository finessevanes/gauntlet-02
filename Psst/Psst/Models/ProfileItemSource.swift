//
//  ProfileItemSource.swift
//  Psst
//
//  Created by Caleb (Coder Agent) on 10/24/25.
//  PR #007: Contextual Intelligence (Auto Client Profiles)
//

import Foundation

/// Source of a profile item (AI-extracted or manually added)
enum ProfileItemSource: String, Codable {
    case ai
    case manual

    /// Display name for UI
    var displayName: String {
        switch self {
        case .ai: return "AI Extracted"
        case .manual: return "Manually Added"
        }
    }
}
