//
//  UserRow.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #9
//  Reusable user row component for contact selection
//

import SwiftUI

/// Reusable row component displaying user information
/// Shows user avatar (initials), display name, and email
struct UserRow: View {
    // MARK: - Properties
    
    let user: User
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar with initials
            Circle()
                .fill(Color.blue)
                .frame(width: 48, height: 48)
                .overlay(
                    Text(getInitials(from: user.displayName))
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            // User information
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Methods
    
    /// Extract initials from display name (max 2 characters)
    /// - Parameter name: Full display name
    /// - Returns: Initials (e.g., "John Doe" -> "JD")
    private func getInitials(from name: String) -> String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            // First letter of first name + first letter of last name
            let first = String(components[0].prefix(1))
            let last = String(components[1].prefix(1))
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            // Just first letter of single name
            return String(first.prefix(1)).uppercased()
        } else {
            // Fallback for empty name
            return "?"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        UserRow(user: User(
            id: "1",
            email: "alice@example.com",
            displayName: "Alice Johnson"
        ))
        
        Divider()
        
        UserRow(user: User(
            id: "2",
            email: "bob@example.com",
            displayName: "Bob Smith"
        ))
        
        Divider()
        
        UserRow(user: User(
            id: "3",
            email: "carol@example.com",
            displayName: "Carol"
        ))
    }
    .padding()
}

