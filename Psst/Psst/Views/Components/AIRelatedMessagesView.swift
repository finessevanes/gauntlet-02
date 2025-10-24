//
//  AIRelatedMessagesView.swift
//  Psst
//
//  Created by Caleb (AI Agent) on PR #006
//  Displays related messages found via semantic search
//

import SwiftUI

/// Displays a list of related messages with timestamps and sender names
struct AIRelatedMessagesView: View {
    let relatedMessages: [RelatedMessage]
    let onMessageTap: ((String) -> Void)?
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Related Conversations")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Related messages list
            ScrollView {
                if relatedMessages.isEmpty {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("No related conversations found")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Try searching with different keywords")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(40)
                } else {
                    VStack(spacing: 12) {
                        ForEach(relatedMessages) { message in
                            RelatedMessageRow(message: message)
                                .onTapGesture {
                                    onMessageTap?(message.messageID)
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

/// Individual row for a related message
struct RelatedMessageRow: View {
    let message: RelatedMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(message.senderName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    // Relevance indicator
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(message.relevanceColor)
                    
                    Text(message.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(message.text)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    AIRelatedMessagesView(
        relatedMessages: [
            RelatedMessage(
                id: "1",
                messageID: "msg1",
                text: "My knee has been bothering me after squats",
                senderName: "John Doe",
                timestamp: Date().addingTimeInterval(-14 * 24 * 60 * 60),
                relevanceScore: 0.92
            ),
            RelatedMessage(
                id: "2",
                messageID: "msg2",
                text: "Should I avoid squats or just modify them?",
                senderName: "John Doe",
                timestamp: Date().addingTimeInterval(-10 * 24 * 60 * 60),
                relevanceScore: 0.87
            ),
            RelatedMessage(
                id: "3",
                messageID: "msg3",
                text: "Knee feels better after trying lighter weights",
                senderName: "John Doe",
                timestamp: Date().addingTimeInterval(-5 * 24 * 60 * 60),
                relevanceScore: 0.81
            )
        ],
        onMessageTap: nil,
        onDismiss: {}
    )
    .padding()
}

#Preview("Empty State") {
    AIRelatedMessagesView(
        relatedMessages: [],
        onMessageTap: nil,
        onDismiss: {}
    )
    .padding()
}

