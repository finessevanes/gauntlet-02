//
//  AIReminderSheet.swift
//  Psst
//
//  Created by Caleb (AI Agent) on PR #006
//  Bottom sheet for creating reminders from messages
//

import SwiftUI

/// Bottom sheet for creating and editing AI-suggested reminders
struct AIReminderSheet: View {
    let suggestion: ReminderSuggestion
    let onSave: (String, Date) -> Void
    let onCancel: () -> Void
    
    @State private var reminderText: String
    @State private var reminderDate: Date
    
    init(
        suggestion: ReminderSuggestion,
        onSave: @escaping (String, Date) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.suggestion = suggestion
        self.onSave = onSave
        self.onCancel = onCancel
        _reminderText = State(initialValue: suggestion.text)
        _reminderDate = State(initialValue: suggestion.suggestedDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reminder")) {
                    TextField("What to remember", text: $reminderText, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("When")) {
                    DatePicker(
                        "Date & Time",
                        selection: $reminderDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                // Show extracted info if available
                if !suggestion.extractedInfo.isEmpty {
                    Section(header: Text("Extracted Information")) {
                        ForEach(Array(suggestion.extractedInfo.keys.sorted()), id: \.self) { key in
                            HStack {
                                Text(key.capitalized)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(suggestion.extractedInfo[key] ?? "")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Set Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(reminderText, reminderDate)
                    }
                    .disabled(reminderText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    AIReminderSheet(
        suggestion: ReminderSuggestion(
            text: "Follow up with John about knee pain",
            suggestedDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
            extractedInfo: [
                "client": "John",
                "topic": "Injury management",
                "priority": "high"
            ]
        ),
        onSave: { text, date in
            print("Saved: \(text) at \(date)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}

#Preview("Minimal Info") {
    AIReminderSheet(
        suggestion: ReminderSuggestion(
            text: "Follow up on workout plan",
            suggestedDate: Date(),
            extractedInfo: [:]
        ),
        onSave: { _, _ in },
        onCancel: {}
    )
}

