//
//  CalendarEmptyStateView.swift
//  Psst
//
//  Created for PR #010A: Calendar Foundation
//  Empty state view for when there are no events
//

import SwiftUI

struct CalendarEmptyStateView: View {

    var onCreateEvent: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Relaxing icon
            Text("☀️")
                .font(.system(size: 80))

            // Message
            VStack(spacing: 12) {
                Text("No events!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Relax and take some me time :)")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

struct CalendarEmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarEmptyStateView(onCreateEvent: {
            print("Create event tapped")
        })
    }
}
