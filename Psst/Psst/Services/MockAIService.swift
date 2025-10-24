//
//  MockAIService.swift
//  Psst
//
//  Created by Caleb (AI Agent) on PR #006
//  Mock AI service for parallel development while PR #005 (RAG Pipeline) is in progress
//

import Foundation

/// Mock AI service providing realistic contextual action responses for development
/// Simulates network delay and returns contextually appropriate data
class MockAIService {
    
    // MARK: - Private Helpers
    
    /// Simulates network delay for realistic UX testing
    private static func simulateDelay() async {
        let delay = Double.random(in: 0.5...1.5)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
    
    // MARK: - Public Methods
    
    /// Mock implementation of conversation summarization
    /// - Parameter messages: Array of messages to summarize
    /// - Returns: Tuple of (summary text, key points array)
    static func mockSummarize(messages: [Message]) async -> (String, [String]) {
        await simulateDelay()
        
        let messageCount = messages.count
        
        // Generate contextual summary based on message count
        let summary: String
        if messageCount == 0 {
            summary = "No messages to summarize."
        } else if messageCount <= 5 {
            summary = "Brief conversation covering \(messageCount) messages exchanged recently."
        } else {
            summary = "Conversation covering \(messageCount) messages over the past few days. Main topics include workout planning, nutrition guidance, and progress updates."
        }
        
        // Generate contextually relevant key points
        let keyPoints: [String]
        if messageCount == 0 {
            keyPoints = []
        } else {
            // Use actual message content to generate semi-realistic key points
            keyPoints = generateMockKeyPoints(from: messages)
        }
        
        return (summary, keyPoints)
    }
    
    /// Mock implementation of surfacing related context
    /// - Parameter message: The message to find context for
    /// - Returns: Array of related messages with timestamps and relevance scores
    static func mockSurfaceContext(for message: Message) async -> [RelatedMessage] {
        await simulateDelay()
        
        // Detect keywords from message to return contextually appropriate results
        let messageText = message.text.lowercased()
        
        // Generate 3 related messages with decreasing relevance scores
        return [
            RelatedMessage(
                id: UUID().uuidString,
                messageID: "mock_1",
                text: generateRelatedMessageText(for: messageText, relevance: .high),
                senderName: "John Doe",
                timestamp: Date().addingTimeInterval(-14 * 24 * 60 * 60), // 2 weeks ago
                relevanceScore: 0.92
            ),
            RelatedMessage(
                id: UUID().uuidString,
                messageID: "mock_2",
                text: generateRelatedMessageText(for: messageText, relevance: .medium),
                senderName: "John Doe",
                timestamp: Date().addingTimeInterval(-10 * 24 * 60 * 60), // 10 days ago
                relevanceScore: 0.87
            ),
            RelatedMessage(
                id: UUID().uuidString,
                messageID: "mock_3",
                text: generateRelatedMessageText(for: messageText, relevance: .low),
                senderName: "John Doe",
                timestamp: Date().addingTimeInterval(-5 * 24 * 60 * 60), // 5 days ago
                relevanceScore: 0.81
            )
        ]
    }
    
    /// Mock implementation of reminder creation
    /// - Parameters:
    ///   - message: The message to extract reminder from
    ///   - senderName: Name of the message sender
    /// - Returns: Reminder suggestion with pre-filled text and suggested date
    static func mockReminder(from message: Message, senderName: String) async -> ReminderSuggestion {
        await simulateDelay()
        
        // Extract first 50 characters from message for reminder text
        let messagePreview = String(message.text.prefix(50))
        let reminderText = messagePreview.count < message.text.count 
            ? "Follow up with \(senderName) about: \(messagePreview)..."
            : "Follow up with \(senderName) about: \(messagePreview)"
        
        // Suggest tomorrow at 9am
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let suggestedDate = Calendar.current.date(from: components) ?? tomorrow
        
        // Extract contextual info (detect keywords)
        let extractedInfo = extractInfo(from: message.text, senderName: senderName)
        
        return ReminderSuggestion(
            text: reminderText,
            suggestedDate: suggestedDate,
            extractedInfo: extractedInfo
        )
    }
    
    // MARK: - Private Context Generators
    
    /// Generates mock key points from messages
    private static func generateMockKeyPoints(from messages: [Message]) -> [String] {
        var keyPoints: [String] = []
        
        // Analyze message content for common keywords
        let allText = messages.map { $0.text.lowercased() }.joined(separator: " ")
        
        if allText.contains("pain") || allText.contains("knee") || allText.contains("shoulder") || allText.contains("injury") {
            keyPoints.append("Discussed injury concerns and modifications needed")
        }
        
        if allText.contains("workout") || allText.contains("exercise") || allText.contains("training") {
            keyPoints.append("Reviewed workout plan and exercise progression")
        }
        
        if allText.contains("diet") || allText.contains("nutrition") || allText.contains("eating") || allText.contains("protein") {
            keyPoints.append("Covered nutrition and dietary adjustments")
        }
        
        if allText.contains("progress") || allText.contains("weight") || allText.contains("goal") {
            keyPoints.append("Tracked progress toward fitness goals")
        }
        
        if allText.contains("schedule") || allText.contains("time") || allText.contains("session") {
            keyPoints.append("Discussed scheduling and session availability")
        }
        
        // If no keywords detected, provide generic key points
        if keyPoints.isEmpty {
            keyPoints = [
                "General fitness discussion and questions",
                "Planning next steps and adjustments",
                "Client motivation and check-in"
            ]
        }
        
        return Array(keyPoints.prefix(5)) // Return max 5 key points
    }
    
    /// Generates related message text based on detected keywords
    private static func generateRelatedMessageText(for messageText: String, relevance: RelevanceLevel) -> String {
        // Detect keywords and return contextually similar messages
        if messageText.contains("knee") || messageText.contains("pain") {
            switch relevance {
            case .high:
                return "My knee has been bothering me after squats"
            case .medium:
                return "Should I avoid squats or just modify them?"
            case .low:
                return "Knee feels better after trying lighter weights"
            }
        } else if messageText.contains("diet") || messageText.contains("nutrition") {
            switch relevance {
            case .high:
                return "Question about protein intake and macros"
            case .medium:
                return "Struggling to stick to the meal plan"
            case .low:
                return "Noticed better energy with the new diet"
            }
        } else if messageText.contains("workout") || messageText.contains("exercise") {
            switch relevance {
            case .high:
                return "Can we adjust the workout schedule?"
            case .medium:
                return "Finding the exercises challenging but manageable"
            case .low:
                return "Completed all sets this week!"
            }
        } else {
            // Generic related messages for any other content
            switch relevance {
            case .high:
                return "Following up on what we discussed earlier"
            case .medium:
                return "Quick question about our last conversation"
            case .low:
                return "Thanks for the advice, it's been helpful"
            }
        }
    }
    
    /// Extracts contextual information from message text
    private static func extractInfo(from text: String, senderName: String) -> [String: String] {
        var info: [String: String] = [
            "client": senderName,
            "topic": "Message follow-up"
        ]
        
        let lowercasedText = text.lowercased()
        
        // Detect topic
        if lowercasedText.contains("pain") || lowercasedText.contains("injury") {
            info["topic"] = "Injury management"
            info["priority"] = "high"
        } else if lowercasedText.contains("workout") || lowercasedText.contains("exercise") {
            info["topic"] = "Workout planning"
            info["priority"] = "medium"
        } else if lowercasedText.contains("diet") || lowercasedText.contains("nutrition") {
            info["topic"] = "Nutrition guidance"
            info["priority"] = "medium"
        } else {
            info["priority"] = "medium"
        }
        
        return info
    }
    
    /// Relevance levels for generating related messages
    private enum RelevanceLevel {
        case high, medium, low
    }
}

