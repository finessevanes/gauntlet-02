//
//  AIActionCoordinator.swift
//  Psst
//
//  Refactored from PR #018
//  Shared coordinator for AI function calling, selection, and scheduling
//

import Foundation
import FirebaseAuth
import Combine

/// Callbacks for action coordinator to communicate with ViewModels
protocol AIActionCoordinatorDelegate: AnyObject {
    func coordinator(_ coordinator: AIActionCoordinator, didReceiveMessage text: String)
    func coordinator(_ coordinator: AIActionCoordinator, didEncounterError message: String)
}

/// Coordinates AI function execution, selection handling, and scheduling
@MainActor
class AIActionCoordinator: ObservableObject {

    // MARK: - Published State

    @Published var pendingAction: PendingAction? = nil
    @Published var isExecutingAction: Bool = false
    @Published var lastActionResult: FunctionExecutionResult? = nil
    @Published var pendingSelection: AISelectionRequest? = nil
    @Published var pendingEventConfirmation: PendingEventConfirmation? = nil
    @Published var pendingConflictResolution: PendingConflictResolution? = nil
    @Published var pendingProspectCreation: PendingProspectCreation? = nil

    // MARK: - Dependencies

    private let aiService: AIService
    private let calendarService: CalendarService
    private let contactService: ContactService
    private var backendConversationId: String?

    weak var delegate: AIActionCoordinatorDelegate?

    // MARK: - Initialization

    init(
        aiService: AIService,
        calendarService: CalendarService,
        contactService: ContactService
    ) {
        self.aiService = aiService
        self.calendarService = calendarService
        self.contactService = contactService
    }

    // MARK: - Public Methods

    /// Update the backend conversation ID
    func setConversationId(_ id: String?) {
        self.backendConversationId = id
    }

    /// Handle a function call from AI response
    func handleFunctionCall(name: String, parameters: [String: Any]) {
        let needsValidation = shouldValidateParameters(functionName: name, parameters: parameters)

        if needsValidation {
            validateAndResolveParameters(functionName: name, parameters: parameters)
        } else {
            showConfirmation(functionName: name, parameters: parameters)
        }
    }

    /// Confirm and execute the pending action
    func confirmAction() {
        guard let action = pendingAction else { return }

        isExecutingAction = true
        lastActionResult = nil

        Task {
            do {
                let parametersWithTimezone = addTimezone(to: action.parameters)

                let result = try await aiService.executeFunctionCall(
                    functionName: action.functionName,
                    parameters: parametersWithTimezone,
                    conversationId: backendConversationId
                )

                isExecutingAction = false

                // Check for selection or conflict
                if checkForSelectionRequest(result) {
                    pendingAction = nil
                    return
                }

                if checkForConflictDetected(result, originalParameters: parametersWithTimezone) {
                    pendingAction = nil
                    return
                }

                lastActionResult = result
                pendingAction = nil

                // Notify delegate
                if let resultText = result.result {
                    delegate?.coordinator(self, didReceiveMessage: resultText)
                }

                // Auto-dismiss after 5 seconds
                autoDismissResult(result)

            } catch {
                handleExecutionError(error)
            }
        }
    }

    /// Cancel the pending action
    func cancelAction() {
        pendingAction = nil
        delegate?.coordinator(self, didReceiveMessage: "Action cancelled.")
    }

    /// Dismiss the last action result
    func dismissActionResult() {
        lastActionResult = nil
    }

    // MARK: - Selection Handling

    /// Handle user selection from multiple options
    func handleSelection(_ option: AISelectionRequest.SelectionOption) {
        guard let selection = pendingSelection,
              let context = selection.context else { return }

        var updatedParameters = context.originalParameters.mapValues { $0.value }

        switch selection.selectionType {
        case .contact:
            if context.originalFunction == "scheduleCall" || context.originalFunction == "setReminder" {
                if let userId = option.metadata?["userId"]?.value as? String {
                    updatedParameters["clientId"] = userId
                }
            }

            if context.originalFunction == "sendMessage" {
                if let chatId = option.metadata?["chatId"]?.value as? String {
                    updatedParameters["chatId"] = chatId
                }
            }

            updatedParameters["clientName"] = option.title

        case .time:
            updatedParameters["dateTime"] = option.id

        case .action, .parameter, .generic:
            break
        }

        pendingSelection = nil
        showConfirmation(functionName: context.originalFunction, parameters: updatedParameters)
    }

    /// Cancel the pending selection
    func cancelSelection() {
        pendingSelection = nil
        delegate?.coordinator(self, didReceiveMessage: "Okay, I've cancelled that request.")
    }

    // MARK: - Scheduling Methods

    /// Confirm and create the pending event
    func confirmEventCreation() {
        guard let pending = pendingEventConfirmation else { return }

        isExecutingAction = true

        Task {
            do {
                let trainerId = Auth.auth().currentUser?.uid ?? ""

                _ = try await calendarService.createEvent(
                    trainerId: trainerId,
                    eventType: pending.eventType,
                    title: pending.title,
                    clientId: pending.clientId,
                    prospectId: pending.prospectId,
                    startTime: pending.startTime,
                    endTime: pending.endTime,
                    location: pending.location,
                    notes: pending.notes,
                    createdBy: "ai"
                )

                isExecutingAction = false
                pendingEventConfirmation = nil

                let message = "Scheduled \(pending.eventType.rawValue) with \(pending.clientName) for \(formatDateTime(pending.startTime))"
                delegate?.coordinator(self, didReceiveMessage: message)

            } catch {
                isExecutingAction = false
                let errorMsg = "Failed to create event: \(error.localizedDescription)"
                delegate?.coordinator(self, didEncounterError: errorMsg)
            }
        }
    }

    /// Cancel the pending event confirmation
    func cancelEventCreation() {
        pendingEventConfirmation = nil
        delegate?.coordinator(self, didReceiveMessage: "Okay, I've cancelled that event.")
    }

    /// Select an alternative time for the conflicted event
    func selectAlternativeTime(_ date: Date) {
        guard let pending = pendingConflictResolution else { return }

        isExecutingAction = true

        Task {
            do {
                let trainerId = Auth.auth().currentUser?.uid ?? ""
                let endTime = date.addingTimeInterval(TimeInterval(pending.duration * 60))

                _ = try await calendarService.createEvent(
                    trainerId: trainerId,
                    eventType: pending.eventType,
                    title: pending.title,
                    clientId: pending.clientId,
                    prospectId: pending.prospectId,
                    startTime: date,
                    endTime: endTime,
                    location: pending.location,
                    notes: pending.notes,
                    createdBy: "ai"
                )

                isExecutingAction = false
                pendingConflictResolution = nil

                let message = "Scheduled \(pending.eventType.rawValue) with \(pending.clientName) for \(formatDateTime(date))"
                delegate?.coordinator(self, didReceiveMessage: message)

            } catch {
                isExecutingAction = false
                let errorMsg = "Failed to create event: \(error.localizedDescription)"
                delegate?.coordinator(self, didEncounterError: errorMsg)
            }
        }
    }

    /// Cancel conflict resolution
    func cancelConflictResolution() {
        pendingConflictResolution = nil
        delegate?.coordinator(self, didReceiveMessage: "Okay, I've cancelled that scheduling request.")
    }

    /// Confirm and create prospect, then create event
    func confirmProspectCreation() {
        guard let pending = pendingProspectCreation else { return }

        isExecutingAction = true

        Task {
            do {
                let trainerId = Auth.auth().currentUser?.uid ?? ""

                let prospect = try await contactService.addProspect(name: pending.clientName)

                _ = try await calendarService.createEvent(
                    trainerId: trainerId,
                    eventType: pending.eventType,
                    title: pending.title,
                    prospectId: prospect.id,
                    startTime: pending.startTime,
                    endTime: pending.endTime,
                    location: pending.location,
                    notes: pending.notes,
                    createdBy: "ai"
                )

                isExecutingAction = false
                pendingProspectCreation = nil

                let message = "Added \(pending.clientName) as a prospect and scheduled \(pending.eventType.rawValue) for \(formatDateTime(pending.startTime))"
                delegate?.coordinator(self, didReceiveMessage: message)

            } catch {
                isExecutingAction = false
                let errorMsg = "Failed to create prospect and event: \(error.localizedDescription)"
                delegate?.coordinator(self, didEncounterError: errorMsg)
            }
        }
    }

    /// Cancel prospect creation
    func cancelProspectCreation() {
        pendingProspectCreation = nil
        delegate?.coordinator(self, didReceiveMessage: "Okay, I've cancelled that request.")
    }

    // MARK: - Private Methods

    /// Check if function parameters need validation/resolution
    private func shouldValidateParameters(functionName: String, parameters: [String: Any]) -> Bool {
        switch functionName {
        case "scheduleCall", "setReminder":
            if let _ = parameters["clientName"] as? String,
               parameters["clientId"] == nil {
                return true
            }

        case "sendMessage":
            if let _ = parameters["clientName"] as? String,
               parameters["chatId"] == nil {
                return true
            }

        default:
            break
        }

        return false
    }

    /// Validate parameters by calling backend
    private func validateAndResolveParameters(functionName: String, parameters: [String: Any]) {
        isExecutingAction = true

        Task {
            do {
                let parametersWithTimezone = addTimezone(to: parameters)

                let result = try await aiService.executeFunctionCall(
                    functionName: functionName,
                    parameters: parametersWithTimezone,
                    conversationId: backendConversationId
                )

                isExecutingAction = false

                if checkForSelectionRequest(result) {
                    return
                }

                if checkForConflictDetected(result, originalParameters: parametersWithTimezone) {
                    return
                }

                if result.success {
                    lastActionResult = result

                    if let resultText = result.result {
                        delegate?.coordinator(self, didReceiveMessage: resultText)
                    }

                    autoDismissResult(result)
                } else {
                    lastActionResult = result
                    autoDismissResult(result)
                }

            } catch {
                handleExecutionError(error)
            }
        }
    }

    /// Show confirmation card for the action
    private func showConfirmation(functionName: String, parameters: [String: Any]) {
        let action = PendingAction(
            functionName: functionName,
            parameters: parameters,
            timestamp: Date()
        )
        pendingAction = action
    }

    /// Check if error response contains a selection request
    private func checkForSelectionRequest(_ result: FunctionExecutionResult) -> Bool {
        guard !result.success,
              result.result == "SELECTION_REQUIRED",
              let data = result.data else {
            return false
        }

        if let selectionRequest = AISelectionRequest.fromResponse(data) {
            pendingSelection = selectionRequest

            // Notify delegate about selection prompt
            delegate?.coordinator(self, didReceiveMessage: selectionRequest.prompt)

            return true
        }

        return false
    }

    /// Check if error response contains a conflict detection
    private func checkForConflictDetected(_ result: FunctionExecutionResult, originalParameters: [String: Any]) -> Bool {
        guard !result.success,
              result.result == "CONFLICT_DETECTED",
              let data = result.data else {
            return false
        }

        guard let conflictResolution = ConflictResolutionParser.parse(data: data, originalParameters: originalParameters) else {
            return false
        }

        pendingConflictResolution = conflictResolution

        // Notify delegate about conflict
        delegate?.coordinator(self, didReceiveMessage: "There's a conflict at that time. I found some alternative times for you.")

        return true
    }

    /// Add timezone to parameters
    private func addTimezone(to parameters: [String: Any]) -> [String: Any] {
        var parametersWithTimezone = parameters
        parametersWithTimezone["timezone"] = TimeZone.current.identifier
        return parametersWithTimezone
    }

    /// Auto-dismiss result after delay
    private func autoDismissResult(_ result: FunctionExecutionResult) {
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if lastActionResult?.actionId == result.actionId {
                lastActionResult = nil
            }
        }
    }

    /// Handle execution error
    private func handleExecutionError(_ error: Error) {
        isExecutingAction = false

        let errorResult = FunctionExecutionResult(
            success: false,
            actionId: nil,
            result: error.localizedDescription,
            data: nil
        )
        lastActionResult = errorResult

        delegate?.coordinator(self, didEncounterError: error.localizedDescription)

        autoDismissResult(errorResult)
    }

    /// Helper to format date and time
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
