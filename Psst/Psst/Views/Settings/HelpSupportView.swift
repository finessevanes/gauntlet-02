//
//  HelpSupportView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #006C
//  Placeholder view for help and support (to be implemented in Phase 2)
//

import SwiftUI

/// Placeholder view for help and support resources
/// Full implementation deferred to Phase 2
struct HelpSupportView: View {
    var body: some View {
        List {
            Section {
                Text("Help & support resources coming soon")
                    .foregroundColor(.secondary)
                    .font(.body)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HelpSupportView()
    }
}

