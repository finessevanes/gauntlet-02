//
//  ActionResultViews.swift
//  Psst
//
//  Created by AI Assistant for PR #008 - AI Function Calling
//

import SwiftUI

/// Success view for completed actions
struct ActionSuccessView: View {
    let result: FunctionExecutionResult
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title2)

            // Message
            VStack(alignment: .leading, spacing: 4) {
                Text("Action Complete")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                if let message = result.result {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

/// Error view for failed actions
struct ActionErrorView: View {
    let result: FunctionExecutionResult
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Error icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.title2)

                // Message
                VStack(alignment: .leading, spacing: 4) {
                    Text("Action Failed")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    if let message = result.result {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                }

                Spacer()
            }

            // Retry button if available
            if let retry = onRetry {
                Button(action: retry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Previews

struct ActionResultViews_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ActionSuccessView(
                result: FunctionExecutionResult(
                    success: true,
                    actionId: "123",
                    result: "Call scheduled with Mike Johnson for October 25 at 2:00 PM",
                    data: nil
                ),
                onDismiss: {}
            )

            ActionErrorView(
                result: FunctionExecutionResult(
                    success: false,
                    actionId: nil,
                    result: "I couldn't find 'Mike Johnson' in your contacts. Please check the name and try again.",
                    data: nil
                ),
                onDismiss: {},
                onRetry: {}
            )

            Spacer()
        }
        .padding(.top, 50)
        .background(Color(.systemGroupedBackground))
    }
}
