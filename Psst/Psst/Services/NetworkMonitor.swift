//
//  NetworkMonitor.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #10
//  Network reachability monitoring using NWPathMonitor
//

import Foundation
import Network
import Combine

/// Monitors network connectivity state using NWPathMonitor
/// Publishes real-time updates for SwiftUI views via @Published properties
class NetworkMonitor: ObservableObject {
    /// Shared singleton instance for app-wide network state access
    static let shared = NetworkMonitor()
    
    /// Current network connection status
    /// True = connected (WiFi, cellular, or ethernet)
    /// False = offline (airplane mode, no network)
    @Published var isConnected: Bool = true
    
    /// Type of network interface currently in use
    /// nil = no connection, .wifi = WiFi, .cellular = Cellular, .wiredEthernet = Ethernet
    @Published var connectionType: NWInterface.InterfaceType?
    
    /// Network path monitor for detecting connectivity changes
    private let monitor = NWPathMonitor()
    
    /// Background queue for network monitoring (not on main thread)
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    /// Private initializer to enforce singleton pattern
    /// Starts monitoring immediately on creation
    private init() {
        startMonitoring()
    }
    
    /// Start monitoring network state changes
    /// Sets up path update handler that fires on every network change
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            // Update published properties on main thread for SwiftUI
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
                
                // Log network state changes for debugging
                if path.status == .satisfied {
                    print("🌐 Network state: Online (\(path.availableInterfaces.first?.type.description ?? "unknown"))")
                } else {
                    print("🌐 Network state: Offline")
                }
            }
        }
        
        // Start monitor on background queue
        monitor.start(queue: queue)
        print("✅ NetworkMonitor started")
    }
    
    /// Stop monitoring network state
    /// Call when network monitoring is no longer needed
    func stopMonitoring() {
        monitor.cancel()
        print("⏹ NetworkMonitor stopped")
    }
}

// MARK: - NWInterface.InterfaceType Extension

extension NWInterface.InterfaceType {
    /// Human-readable description of interface type
    var description: String {
        switch self {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .loopback:
            return "Loopback"
        case .other:
            return "Other"
        @unknown default:
            return "Unknown"
        }
    }
}

