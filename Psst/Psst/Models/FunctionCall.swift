//
//  FunctionCall.swift
//  Psst
//
//  Created by AI Assistant for PR #008 - AI Function Calling
//

import Foundation

/**
 * Pending Action
 *
 * Represents an AI function call awaiting user confirmation
 */
struct PendingAction: Identifiable, Equatable {
    let id = UUID()
    let functionName: String
    let parameters: [String: Any]
    let timestamp: Date

    init(functionName: String, parameters: [String: Any], timestamp: Date = Date()) {
        self.functionName = functionName
        self.parameters = parameters
        self.timestamp = timestamp
    }

    // Equatable conformance - compare by ID
    static func == (lhs: PendingAction, rhs: PendingAction) -> Bool {
        lhs.id == rhs.id
    }

    // Generate human-readable display text
    var displayText: String {
        switch functionName {
        case "scheduleCall":
            return formatScheduleCall()
        case "setReminder":
            return formatSetReminder()
        case "sendMessage":
            return formatSendMessage()
        case "searchMessages":
            return formatSearchMessages()
        default:
            return "Unknown action: \(functionName)"
        }
    }

    // Get parameter value as string
    private func paramValue(_ key: String) -> String? {
        if let value = parameters[key] as? String {
            return value
        }
        if let value = parameters[key] as? Int {
            return String(value)
        }
        if let value = parameters[key] as? Double {
            return String(value)
        }
        return nil
    }

    // Parse dateTime string (handles both with and without timezone)
    private func parseDateTime(_ dateTimeString: String) -> Date? {
        print("🕐 [parseDateTime] Input: '\(dateTimeString)'")
        print("🕐 [parseDateTime] Current timezone: \(TimeZone.current.identifier)")

        // Try ISO8601 with timezone first (e.g., "2025-10-25T14:00:00Z")
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateTimeString) {
            print("✅ [parseDateTime] Parsed WITH timezone: \(date)")
            return date
        }
        print("⚠️ [parseDateTime] Failed ISO8601 with timezone")

        // Try without timezone using DateFormatter (e.g., "2025-10-25T14:00:00")
        // Interpret as LOCAL timezone
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        if let date = dateFormatter.date(from: dateTimeString) {
            print("✅ [parseDateTime] Parsed WITHOUT timezone (as local): \(date)")
            return date
        }
        print("⚠️ [parseDateTime] Failed DateFormatter without timezone")

        print("❌ [parseDateTime] All parsing attempts failed")
        return nil
    }

    private func formatScheduleCall() -> String {
        let clientName = paramValue("clientName") ?? "client"
        let duration = paramValue("duration") ?? "30"

        if let dateTimeString = paramValue("dateTime"),
           let date = parseDateTime(dateTimeString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            let formattedDate = formatter.string(from: date)

            return "Schedule call with \(clientName) on \(formattedDate) (\(duration) min)"
        }

        return "Schedule call with \(clientName)"
    }

    private func formatSetReminder() -> String {
        let reminderText = paramValue("reminderText") ?? "reminder"
        let clientName = paramValue("clientName")

        if let dateTimeString = paramValue("dateTime"),
           let date = parseDateTime(dateTimeString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            let formattedDate = formatter.string(from: date)

            if let client = clientName {
                return "Remind about \(client): \(reminderText) on \(formattedDate)"
            } else {
                return "Reminder: \(reminderText) on \(formattedDate)"
            }
        }

        return "Set reminder: \(reminderText)"
    }

    private func formatSendMessage() -> String {
        let messageText = paramValue("messageText") ?? ""
        let preview = messageText.prefix(50)

        return "Send message: \"\(preview)\(messageText.count > 50 ? "..." : "")\""
    }

    private func formatSearchMessages() -> String {
        let query = paramValue("query") ?? "messages"
        let limit = paramValue("limit") ?? "10"

        return "Search for: \"\(query)\" (up to \(limit) results)"
    }

    // Get formatted parameters for display in confirmation card
    func getFormattedParameters() -> [(String, String)] {
        print("📋 [getFormattedParameters] Called for function: \(functionName)")
        print("📋 [getFormattedParameters] Parameters: \(parameters)")
        var result: [(String, String)] = []

        switch functionName {
        case "scheduleCall":
            print("📋 [getFormattedParameters] Processing scheduleCall")
            if let clientName = paramValue("clientName") {
                print("📋 [getFormattedParameters] Client name: \(clientName)")
                result.append(("Client", clientName))
            }
            if let dateTimeString = paramValue("dateTime") {
                print("📋 [getFormattedParameters] DateTime string: \(dateTimeString)")
                if let date = parseDateTime(dateTimeString) {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .long
                    formatter.timeStyle = .short
                    let formattedString = formatter.string(from: date)
                    print("📋 [getFormattedParameters] Formatted date: \(formattedString)")
                    result.append(("Date & Time", formattedString))
                } else {
                    print("❌ [getFormattedParameters] Failed to parse dateTime")
                }
            } else {
                print("⚠️ [getFormattedParameters] No dateTime parameter found")
            }
            if let duration = paramValue("duration") {
                print("📋 [getFormattedParameters] Duration: \(duration) minutes")
                result.append(("Duration", "\(duration) minutes"))
            }

        case "setReminder":
            if let clientName = paramValue("clientName") {
                result.append(("Client", clientName))
            }
            if let reminderText = paramValue("reminderText") {
                result.append(("Reminder", reminderText))
            }
            if let dateTimeString = paramValue("dateTime"),
               let date = parseDateTime(dateTimeString) {
                let formatter = DateFormatter()
                formatter.dateStyle = .long
                formatter.timeStyle = .short
                result.append(("Due Date", formatter.string(from: date)))
            }

        case "sendMessage":
            if let messageText = paramValue("messageText") {
                result.append(("Message", messageText))
            }

        case "searchMessages":
            if let query = paramValue("query") {
                result.append(("Query", query))
            }
            if let limit = paramValue("limit") {
                result.append(("Max Results", limit))
            }

        default:
            break
        }

        print("📋 [getFormattedParameters] Returning \(result.count) parameters:")
        for (key, value) in result {
            print("📋   - \(key): \(value)")
        }
        return result
    }
}

/**
 * Function Execution Result
 *
 * Result of executing an AI function call
 */
struct FunctionExecutionResult: Equatable {
    let success: Bool
    let actionId: String?
    let result: String?
    let data: [String: Any]?

    init(success: Bool, actionId: String? = nil, result: String? = nil, data: [String: Any]? = nil) {
        self.success = success
        self.actionId = actionId
        self.result = result
        self.data = data
    }

    // Equatable conformance - compare success and actionId
    static func == (lhs: FunctionExecutionResult, rhs: FunctionExecutionResult) -> Bool {
        lhs.success == rhs.success && lhs.actionId == rhs.actionId
    }

    // Parse from Cloud Function response
    static func fromResponse(_ response: [String: Any]) -> FunctionExecutionResult {
        let success = response["success"] as? Bool ?? false
        let actionId = response["actionId"] as? String
        let result = response["result"] as? String
        let error = response["error"] as? String
        let data = response["data"] as? [String: Any]

        return FunctionExecutionResult(
            success: success,
            actionId: actionId,
            result: error ?? result,
            data: data
        )
    }
}
