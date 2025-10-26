//
//  CurrentTimeIndicatorView.swift
//  Psst
//
//  Created for PR #010A: Calendar Foundation
//  Red line indicator showing current time in timeline
//

import SwiftUI

struct CurrentTimeIndicatorView: View {

    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            // Small circle at the left
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)

            // Horizontal line
            Rectangle()
                .fill(Color.red)
                .frame(height: 2)
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

// MARK: - Preview

struct CurrentTimeIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentTimeIndicatorView()
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
