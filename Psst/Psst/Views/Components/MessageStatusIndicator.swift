//
//  MessageStatusIndicator.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #10
//  Status indicator for optimistic UI (sending/queued/failed/delivered)
//

import SwiftUI

/// Visual indicator for message send status
/// Shows gray "Sending...", yellow "Queued", red "Failed - Tap to retry", or nothing (delivered)
struct MessageStatusIndicator: View {
    /// Current send status of the message
    let status: MessageSendStatus?
    
    /// Closure called when user taps retry on failed message
    let onRetry: (() -> Void)?
    
    var body: some View {
        Group {
            switch status {
            case .sending:
                sendingIndicator
                
            case .queued:
                queuedIndicator
                
            case .failed:
                failedIndicator
                
            case .delivered, .none:
                // No indicator for delivered messages or messages without status
                EmptyView()
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Gray "Sending..." text for optimistic messages
    /// PR #21: Enhanced for better dark mode visibility
    private var sendingIndicator: some View {
        Text("Sending...")
            .font(.caption)
            .foregroundColor(.secondary) // Use semantic color for better dark mode support
    }
    
    /// Yellow "Queued" badge for offline messages
    private var queuedIndicator: some View {
        Text("Queued")
            .font(.caption.bold())
            .foregroundColor(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.yellow.opacity(0.3))
            .cornerRadius(4)
    }
    
    /// Red "Failed - Tap to retry" with retry action
    private var failedIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
            
            Text("Failed - Tap to retry")
                .font(.caption)
        }
        .foregroundColor(.red)
        .onTapGesture {
            onRetry?()
        }
    }
    
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        HStack {
            Text("Message bubble")
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(12)
            
            Spacer()
        }
        
        MessageStatusIndicator(status: .sending, onRetry: nil)
        
        Divider()
        
        HStack {
            Text("Message bubble")
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(12)
            
            Spacer()
        }
        
        MessageStatusIndicator(status: .queued, onRetry: nil)
        
        Divider()
        
        HStack {
            Text("Message bubble")
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(12)
            
            Spacer()
        }
        
        MessageStatusIndicator(status: .failed, onRetry: {
            print("Retry tapped")
        })
        
        Divider()
        
        HStack {
            Text("Message bubble")
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(12)
            
            Spacer()
        }
        
        MessageStatusIndicator(status: .delivered, onRetry: nil)
        
        Divider()
        
        HStack {
            Text("Message bubble")
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(12)
            
            Spacer()
        }
        
        MessageStatusIndicator(status: .none, onRetry: nil)
    }
    .padding()
}

