//
//  AISelectionCard.swift
//  Psst
//
//  Created by AI Assistant for PR #008 - AI Selection System
//  Card displaying multiple options for user to choose from
//

import SwiftUI

/// Card for selecting from multiple options when AI needs clarification
struct AISelectionCard: View {
    let request: AISelectionRequest
    let onSelect: (AISelectionRequest.SelectionOption) -> Void
    let onCancel: () -> Void

    @State private var selectedOption: AISelectionRequest.SelectionOption? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: headerIcon)
                    .foregroundColor(.blue)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Assistant")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(request.prompt)
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Spacer()
            }

            // Options list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(request.options) { option in
                        OptionRow(
                            option: option,
                            isSelected: selectedOption?.id == option.id,
                            onTap: {
                                selectedOption = option
                                // Add haptic feedback
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                // Delay to show selection state
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    onSelect(option)
                                }
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 300)

            // Cancel button
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 20, y: 10)
        .padding(.horizontal, 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var headerIcon: String {
        switch request.selectionType {
        case .contact:
            return "person.2.fill"
        case .time:
            return "clock.fill"
        case .action:
            return "bolt.fill"
        case .parameter:
            return "slider.horizontal.3"
        case .generic:
            return "list.bullet"
        }
    }
}

/// Individual option row
struct OptionRow: View {
    let option: AISelectionRequest.SelectionOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                if let iconName = option.icon {
                    if iconName.count == 1 {
                        // Emoji icon
                        Text(iconName)
                            .font(.title2)
                    } else {
                        // SF Symbol
                        Image(systemName: iconName)
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                } else {
                    // Default contact icon
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }

                // Title and subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.body.weight(.medium))
                        .foregroundColor(.primary)

                    if let subtitle = option.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Arrow indicator
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption.weight(.semibold))
            }
            .padding(16)
            .background(backgroundView)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(option.title)\(option.subtitle.map { ", \($0)" } ?? "")")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to select")
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
    }
}

// MARK: - Preview

struct AISelectionCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            AISelectionCard(
                request: AISelectionRequest(
                    selectionType: .contact,
                    prompt: "Who did you mean?",
                    options: [
                        AISelectionRequest.SelectionOption(
                            id: "user1",
                            title: "Mike Johnson",
                            subtitle: "mike.j@example.com",
                            icon: "👤",
                            metadata: ["chatId": AnyCodable("chat123")]
                        ),
                        AISelectionRequest.SelectionOption(
                            id: "user2",
                            title: "Mike Chen",
                            subtitle: "mike.chen@example.com",
                            icon: "👤",
                            metadata: ["chatId": AnyCodable("chat456")]
                        ),
                        AISelectionRequest.SelectionOption(
                            id: "user3",
                            title: "Michael Williams",
                            subtitle: "m.williams@example.com",
                            icon: "👤",
                            metadata: ["chatId": AnyCodable("chat789")]
                        )
                    ],
                    context: AISelectionRequest.SelectionContext(
                        originalFunction: "sendMessage",
                        originalParameters: [
                            "clientName": AnyCodable("Mike"),
                            "messageText": AnyCodable("How's your training going?")
                        ]
                    )
                ),
                onSelect: { option in
                    print("Selected: \(option.title)")
                },
                onCancel: {
                    print("Cancelled")
                }
            )
        }
    }
}
