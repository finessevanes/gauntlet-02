//
//  Contact.swift
//  Psst
//
//  Created for PR #009: Trainer-Client Relationship System
//

import Foundation

/// Protocol for unified handling of clients and prospects
protocol Contact: Identifiable, Codable {
    var id: String { get }
    var displayName: String { get }
    var addedAt: Date { get }
}

