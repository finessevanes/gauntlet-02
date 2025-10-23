//
//  Logger.swift
//  Psst
//
//  Lightweight timestamped logging utility.
//

import Foundation

/// Simple logger that prefixes messages with ISO8601 timestamps and category
enum Log {
    private static let formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    /// Logs an info message with a category prefix
    /// - Parameters:
    ///   - category: Component or service name
    ///   - message: Message to print
    static func i(_ category: String, _ message: String) {
        let ts = formatter.string(from: Date())
        print("[\(ts)] [\(category)] \(message)")
    }

    /// Logs an error message with a category prefix
    /// - Parameters:
    ///   - category: Component or service name
    ///   - message: Message to print
    static func e(_ category: String, _ message: String) {
        let ts = formatter.string(from: Date())
        print("[\(ts)] [\(category)] ❌ \(message)")
    }
    
    /// Logs a warning message with a category prefix
    /// - Parameters:
    ///   - category: Component or service name
    ///   - message: Message to print
    static func w(_ category: String, _ message: String) {
        let ts = formatter.string(from: Date())
        print("[\(ts)] [\(category)] ⚠️ \(message)")
    }
    
    /// Logs a debug message with a category prefix
    /// - Parameters:
    ///   - category: Component or service name
    ///   - message: Message to print
    static func d(_ category: String, _ message: String) {
        let ts = formatter.string(from: Date())
        print("[\(ts)] [\(category)] 🔍 \(message)")
    }
}

/// Helper to measure durations
struct Stopwatch {
    private let start: DispatchTime

    init() {
        start = DispatchTime.now()
    }

    /// Elapsed milliseconds since init
    var ms: Int {
        let nano = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
        return Int(Double(nano) / 1_000_000.0)
    }
}


