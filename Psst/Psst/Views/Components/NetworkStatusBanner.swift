//
//  NetworkStatusBanner.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #10
//  Online/offline indicator banner for network state awareness
//

import SwiftUI

/// Banner displaying network status (offline, reconnecting, connected)
/// Shows at top of chat view with queue count when offline
struct NetworkStatusBanner: View {
    /// Network monitor for connection state
    @ObservedObject var networkMonitor: NetworkMonitor
    
    /// Count of queued messages for this chat
    @Binding var queueCount: Int
    
    /// Controls brief "Connected" banner visibility
    @State private var showConnectedBanner = false
    
    /// Previous connection state for detecting transitions
    @State private var previouslyConnected = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Offline banner (persistent while offline)
            if !networkMonitor.isConnected {
                offlineBanner
                    .transition(.move(edge: .top))
            }
            
            // Connected banner (brief, auto-dismisses)
            if showConnectedBanner && networkMonitor.isConnected {
                connectedBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
        .animation(.easeInOut(duration: 0.3), value: showConnectedBanner)
        .onChange(of: networkMonitor.isConnected) { oldValue, newValue in
            handleConnectionChange(from: oldValue, to: newValue)
        }
        .onAppear {
            previouslyConnected = networkMonitor.isConnected
        }
    }
    
    // MARK: - Subviews
    
    /// Offline banner with yellow warning color
    private var offlineBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.caption)
            
            Text(queueCount > 0
                 ? "Offline - \(queueCount) message\(queueCount == 1 ? "" : "s") queued"
                 : "Offline - Messages will send when reconnected")
                .font(.caption)
                .lineLimit(1)
        }
        .foregroundColor(.black)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color.yellow.opacity(0.2))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    /// Connected banner with green success color (auto-dismisses)
    private var connectedBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi")
                .font(.caption)
            
            Text("Connected")
                .font(.caption)
        }
        .foregroundColor(.white)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color.green)
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Helpers
    
    /// Handle connection state changes
    /// Shows brief "Connected" banner on reconnect
    private func handleConnectionChange(from oldValue: Bool, to newValue: Bool) {
        // Reconnected: was offline, now online
        if !oldValue && newValue {
            showConnectedBanner = true
            
            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showConnectedBanner = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        // Preview: Offline with queued messages
        NetworkStatusBanner(
            networkMonitor: NetworkMonitor.shared,
            queueCount: .constant(3)
        )
        
        Spacer()
        
        Text("Chat content below...")
            .foregroundColor(.gray)
    }
}

