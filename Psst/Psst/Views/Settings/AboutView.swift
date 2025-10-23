//
//  AboutView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #006C
//  Placeholder view for app information (to be implemented in Phase 2)
//

import SwiftUI

/// Placeholder view for app information and about screen
/// Full implementation deferred to Phase 2
struct AboutView: View {
    var body: some View {
        List {
            Section {
                Text("App information coming soon")
                    .foregroundColor(.secondary)
                    .font(.body)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AboutView()
    }
}

