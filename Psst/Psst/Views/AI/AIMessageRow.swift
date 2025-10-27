//
//  AIMessageRow.swift
//  Psst
//
//  Created by AI Assistant on PR #002
//  iOS AI Infrastructure Foundation
//

import SwiftUI

/// Individual AI message bubble component
struct AIMessageRow: View {
    let message: AIMessage
    var onSpeakerTap: ((String, String) -> Void)? = nil // Phase 2: TTS toggle (messageId, text)
    var isCurrentlyPlaying: Bool = false // Phase 2: Is this message currently playing?

    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                // Message bubble
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(messageBackgroundColor)
                    .foregroundColor(messageTextColor)
                    .cornerRadius(18)
                    .textSelection(.enabled)
                
                // Timestamp and status
                HStack(spacing: 4) {
                    // Speaker/Stop button for AI messages (Phase 2)
                    if !message.isFromUser, let onSpeakerTap = onSpeakerTap {
                        Button(action: {
                            onSpeakerTap(message.id, message.text)
                        }) {
                            Image(systemName: isCurrentlyPlaying ? "stop.circle.fill" : "speaker.wave.2.fill")
                                .font(.caption)
                                .foregroundColor(isCurrentlyPlaying ? .red : .blue)
                        }
                    }

                    Text(formatTimestamp(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if message.isFromUser {
                        statusIcon
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxWidth: 280, alignment: message.isFromUser ? .trailing : .leading)
            
            if !message.isFromUser {
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    // MARK: - Computed Properties
    
    private var messageBackgroundColor: Color {
        if message.isFromUser {
            return Color.blue
        } else {
            return Color(.systemGray5)
        }
    }
    
    private var messageTextColor: Color {
        if message.isFromUser {
            return .white
        } else {
            return .primary
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch message.status {
        case .sending:
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundColor(.secondary)
        case .delivered:
            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundColor(.blue)
        case .failed:
            Image(systemName: "exclamationmark.circle")
                .font(.caption2)
                .foregroundColor(.red)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
        } else {
            formatter.dateFormat = "MMM d"
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - Previews

#Preview("User Message") {
    AIMessageRow(
        message: AIMessage(
            text: "Hello AI, how can you help me today?",
            isFromUser: true,
            timestamp: Date(),
            status: .delivered
        )
    )
}

#Preview("AI Message") {
    AIMessageRow(
        message: AIMessage(
            text: "Hi! I'm your AI assistant. I can help you search past conversations, summarize chats, and answer questions about your clients. What would you like to know?",
            isFromUser: false,
            timestamp: Date(),
            status: .delivered
        )
    )
}

#Preview("Sending Status") {
    AIMessageRow(
        message: AIMessage(
            text: "What can you do?",
            isFromUser: true,
            timestamp: Date(),
            status: .sending
        )
    )
}

#Preview("Failed Status") {
    AIMessageRow(
        message: AIMessage(
            text: "Show me recent messages",
            isFromUser: true,
            timestamp: Date(),
            status: .failed
        )
    )
}

