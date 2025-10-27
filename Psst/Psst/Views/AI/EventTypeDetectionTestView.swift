//
//  EventTypeDetectionTestView.swift
//  Psst
//
//  Test view for PR #010B event type detection
//  Open this file in Xcode and view the preview to test detection logic
//

import SwiftUI

struct EventTypeDetectionTestView: View {
    @State private var testQuery: String = "schedule a session with Sam tomorrow at 6pm"

    private let aiService = AIService()

    private var detectedType: CalendarEvent.EventType {
        aiService.detectEventType(from: testQuery)
    }

    private var detectedIcon: String {
        switch detectedType {
        case .training: return "🏋️"
        case .call: return "📞"
        case .adhoc: return "📅"
        }
    }

    private var detectedText: String {
        switch detectedType {
        case .training: return "Training Session"
        case .call: return "Call"
        case .adhoc: return "Adhoc Appointment"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Event Type Detection Test")
                .font(.title2.bold())

            // Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Test Query:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextEditor(text: $testQuery)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            Divider()

            // Result
            VStack(spacing: 12) {
                Text("Detected Type:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Text(detectedIcon)
                        .font(.system(size: 40))

                    Text(detectedText)
                        .font(.title3.bold())
                }

                Text(detectedType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)

            Spacer()

            // Quick Test Examples
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Tests:")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                ForEach(testExamples, id: \.self) { example in
                    Button(action: {
                        testQuery = example
                    }) {
                        Text(example)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
    }

    private let testExamples = [
        "schedule a session with Sam tomorrow at 6pm",
        "schedule a call with John next Tuesday at 3pm",
        "I have a doctor appointment at 2pm",
        "book a training session with Sarah on Friday",
        "set up a zoom meeting with the team",
        "workout with Mike at 5pm",
        "dentist appointment next week"
    ]
}

#Preview {
    EventTypeDetectionTestView()
}
