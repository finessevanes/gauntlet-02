//
//  MockAIData.swift
//  Psst
//
//  Created by AI Assistant on PR #002
//  iOS AI Infrastructure Foundation
//

import Foundation

/// Provides mock AI conversation data for development and testing
struct MockAIData {
    
    // MARK: - Sample Conversation
    
    /// Sample AI conversation with realistic exchanges
    static let sampleConversation: AIConversation = {
        let messages: [AIMessage] = [
            AIMessage(
                text: "Hello AI",
                isFromUser: true,
                timestamp: Date().addingTimeInterval(-300), // 5 minutes ago
                status: .delivered
            ),
            AIMessage(
                text: "Hi! I'm your AI assistant. How can I help you today?",
                isFromUser: false,
                timestamp: Date().addingTimeInterval(-295),
                status: .delivered
            ),
            AIMessage(
                text: "What can you do?",
                isFromUser: true,
                timestamp: Date().addingTimeInterval(-200),
                status: .delivered
            ),
            AIMessage(
                text: "I can help you search past conversations, summarize chats, and answer questions about your clients. What would you like to know?",
                isFromUser: false,
                timestamp: Date().addingTimeInterval(-195),
                status: .delivered
            ),
            AIMessage(
                text: "Show me recent messages from John",
                isFromUser: true,
                timestamp: Date().addingTimeInterval(-100),
                status: .delivered
            ),
            AIMessage(
                text: "Here are John's recent messages from the past week:\n\n• \"Can we meet tomorrow?\" (2 days ago)\n• \"Thanks for the update!\" (1 day ago)\n• \"Looking forward to our call\" (Today)\n\nWould you like me to summarize his conversation?",
                isFromUser: false,
                timestamp: Date().addingTimeInterval(-95),
                status: .delivered
            )
        ]
        
        return AIConversation(
            id: "mock-conversation-1",
            messages: messages,
            createdAt: Date().addingTimeInterval(-300),
            updatedAt: Date().addingTimeInterval(-95)
        )
    }()
    
    // MARK: - Mock Response Generator
    
    /// Generates mock response text based on user query
    /// - Parameter query: User's message
    /// - Returns: Contextual mock response text
    static func mockResponse(for query: String) -> String {
        let lowercased = query.lowercased()
        
        if lowercased.contains("hello") || lowercased.contains("hi") || lowercased.contains("hey") {
            return "Hi! I'm your AI assistant. How can I help you today?"
        }
        
        if lowercased.contains("help") || lowercased.contains("what can you do") {
            return "I can help you with:\n\n• Searching past conversations\n• Summarizing chats\n• Finding specific client messages\n• Answering questions about your conversations\n\nWhat would you like to try?"
        }
        
        if lowercased.contains("search") {
            return "I can search through all your conversations. Try asking:\n\n• 'Find messages about [topic]'\n• 'Show messages from [client name]'\n• 'When did I last talk to [client]?'"
        }
        
        if lowercased.contains("summarize") {
            return "I can summarize conversations to help you quickly catch up. Which conversation would you like me to summarize?"
        }
        
        if lowercased.contains("client") || lowercased.contains("message") {
            return "I can help you find messages from specific clients. Try asking:\n\n• 'Show me recent messages from [name]'\n• 'What did [name] say about [topic]?'\n• 'Find unread messages from [name]'"
        }
        
        if lowercased.contains("schedule") || lowercased.contains("remind") {
            return "Scheduling and reminders are coming soon! For now, I can help you search and summarize conversations."
        }
        
        // Default response
        return "I understand you're asking about '\(query)'. Once the AI backend is ready, I'll be able to provide more detailed answers. For now, try asking about searching messages, summarizing conversations, or finding client information."
    }
    
    // MARK: - Sample Messages
    
    /// Collection of sample user messages for testing
    static let sampleUserQueries: [String] = [
        "Hello AI",
        "What can you do?",
        "Show me recent messages from Sarah",
        "Summarize my conversation with Mike",
        "Find messages about the project deadline",
        "When did I last talk to Jennifer?",
        "Help me search for client updates"
    ]
    
    /// Collection of sample AI responses for testing
    static let sampleAIResponses: [String] = [
        "Hi! I'm your AI assistant. How can I help you today?",
        "I can help you search past conversations, summarize chats, and answer questions about your clients.",
        "Here are Sarah's recent messages from the past week...",
        "I've summarized Mike's conversation: He asked about the project timeline and confirmed availability for next week.",
        "I found 3 messages mentioning 'project deadline'...",
        "You last spoke with Jennifer 2 days ago at 3:45 PM.",
        "What type of client updates are you looking for?"
    ]
}

