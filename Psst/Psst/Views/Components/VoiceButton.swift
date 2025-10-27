//
//  VoiceButton.swift
//  Psst
//
//  Created by Caleb (AI Agent) on 10/26/25.
//

import SwiftUI

/// Voice recording button with state-based styling
struct VoiceButton: View {
    // MARK: - Button State

    enum ButtonState {
        case idle
        case recording
        case transcribing
        case error
    }

    // MARK: - Properties

    let state: ButtonState
    let action: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Pulsing background circle (only when recording)
                if state == .recording {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .scaleEffect(isPulsing ? 1.3 : 1.0)
                        .opacity(isPulsing ? 0.0 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: false),
                            value: isPulsing
                        )
                }

                // Icon
                Group {
                    switch state {
                    case .idle:
                        Image(systemName: "mic.fill")
                            .foregroundColor(.gray)
                    case .recording:
                        Image(systemName: "mic.fill")
                            .foregroundColor(.red)
                    case .transcribing:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    case .error:
                        Image(systemName: "mic.slash.fill")
                            .foregroundColor(.red)
                    }
                }
                .frame(width: 24, height: 24)
            }
        }
        .frame(width: 44, height: 44)
        .disabled(state == .transcribing)
        .onAppear {
            if state == .recording {
                isPulsing = true
            }
        }
        .onChange(of: state) { newState in
            isPulsing = (newState == .recording)
        }
    }
}

#Preview("Idle") {
    VoiceButton(state: .idle, action: {})
}

#Preview("Recording") {
    VoiceButton(state: .recording, action: {})
}

#Preview("Transcribing") {
    VoiceButton(state: .transcribing, action: {})
}

#Preview("Error") {
    VoiceButton(state: .error, action: {})
}
