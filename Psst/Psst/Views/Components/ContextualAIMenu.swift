//
//  ContextualAIMenu.swift
//  Psst
//
//  Created by Caleb (AI Agent) on PR #006
//  Long-press menu showing AI action options
//

import SwiftUI

/// Contextual menu displaying AI actions available for a message
struct ContextualAIMenu: View {
    let message: Message
    let onActionSelected: (AIContextAction) -> Void
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(AIContextAction.allCases) { action in
                Button {
                    onActionSelected(action)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: action.icon)
                            .font(.system(size: 18))
                            .foregroundColor(.accentColor)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(action.rawValue)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(action.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 8)
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        ContextualAIMenu(
            message: Message(
                id: "1",
                text: "My knee has been hurting",
                senderID: "user1"
            ),
            onActionSelected: { action in
                print("Selected: \(action.rawValue)")
            },
            onDismiss: {}
        )
        .padding()
    }
}

