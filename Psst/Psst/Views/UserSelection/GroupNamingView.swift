//
//  GroupNamingView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #11
//  Modal sheet for naming a group chat
//

import SwiftUI

/// Group naming view for entering a name when creating a group chat
/// Presented as a modal sheet with validation for 1-50 character names
struct GroupNamingView: View {
    // MARK: - Properties
    
    /// Binding to the group name text
    @Binding var groupName: String
    
    /// Selected user IDs for display
    let selectedUserIDs: [String]
    
    /// Callback when user cancels
    let onCancel: () -> Void
    
    /// Callback when user confirms group creation
    let onCreate: (String) -> Void
    
    // MARK: - State Properties
    
    @FocusState private var isTextFieldFocused: Bool
    
    // MARK: - Computed Properties
    
    /// Whether the create button should be enabled
    private var isCreateEnabled: Bool {
        let trimmed = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 50
    }
    
    /// Character count text
    private var characterCountText: String {
        "\(groupName.count)/50"
    }
    
    /// Character count color (red if over limit)
    private var characterCountColor: Color {
        groupName.count > 50 ? .red : .secondary
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Heading
                Text("Name Your Group")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 20)
                
                // Text field for group name
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Group Name", text: $groupName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                        .focused($isTextFieldFocused)
                        .onChange(of: groupName) { oldValue, newValue in
                            // Limit to 50 characters
                            if newValue.count > 50 {
                                groupName = String(newValue.prefix(50))
                            }
                        }
                    
                    // Character count
                    Text(characterCountText)
                        .font(.caption)
                        .foregroundColor(characterCountColor)
                }
                .padding(.horizontal, 20)
                
                // Selected members info
                VStack(spacing: 8) {
                    Text("\(selectedUserIDs.count) members selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    // Cancel button
                    Button(action: {
                        onCancel()
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                    
                    // Create button
                    Button(action: {
                        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if isCreateEnabled {
                            onCreate(trimmedName)
                        }
                    }) {
                        Text("Create")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isCreateEnabled ? Color.blue : Color(.systemGray4))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(!isCreateEnabled)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .onAppear {
                // Auto-focus text field
                isTextFieldFocused = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GroupNamingView(
        groupName: .constant(""),
        selectedUserIDs: ["user1", "user2", "user3"],
        onCancel: {},
        onCreate: { _ in }
    )
}

