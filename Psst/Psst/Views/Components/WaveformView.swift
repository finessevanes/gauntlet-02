//
//  WaveformView.swift
//  Psst
//
//  Created by Caleb (AI Agent) on 10/26/25.
//  PR #011 - Phase 3: UI Polish
//

import SwiftUI

/// Animated waveform visualization for voice recording
struct WaveformView: View {
    let audioLevel: Float // 0.0 to 1.0

    // MARK: - Constants

    private enum Layout {
        static let barCount: Int = 5
        static let barWidth: CGFloat = 3
        static let barSpacing: CGFloat = 4
        static let barCornerRadius: CGFloat = 2
        static let minBarHeight: CGFloat = 4
        static let maxBarHeight: CGFloat = 30
        static let containerHeight: CGFloat = 30
        static let animationDuration: CGFloat = 0.15
        static let initialLevel: CGFloat = 0.1
        static let randomnessRange: ClosedRange<CGFloat> = 0.8...1.2
        static let edgeHeightReduction: Float = 0.5
    }

    @State private var animatedLevels: [CGFloat] = Array(repeating: Layout.initialLevel, count: Layout.barCount)

    var body: some View {
        HStack(spacing: Layout.barSpacing) {
            ForEach(0..<Layout.barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: Layout.barCornerRadius)
                    .fill(Color.blue)
                    .frame(width: Layout.barWidth, height: barHeight(for: index))
                    .animation(.easeInOut(duration: Layout.animationDuration), value: animatedLevels[index])
            }
        }
        .frame(height: Layout.containerHeight)
        .onChange(of: audioLevel) { newLevel in
            updateWaveform(level: newLevel)
        }
        .onAppear {
            updateWaveform(level: audioLevel)
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let level = animatedLevels[index]
        return Layout.minBarHeight + (Layout.maxBarHeight - Layout.minBarHeight) * level
    }

    private func updateWaveform(level: Float) {
        // Create wave effect with different heights for each bar
        let baseLevel = CGFloat(level)

        // Middle bars are tallest, edges are shorter (wave pattern)
        for i in 0..<Layout.barCount {
            let distanceFromCenter = abs(Float(i) - Float(Layout.barCount - 1) / 2.0)
            let heightMultiplier = 1.0 - (distanceFromCenter / Float(Layout.barCount) * Layout.edgeHeightReduction)

            // Add randomness for natural effect
            let randomness = CGFloat.random(in: Layout.randomnessRange)
            let targetLevel = baseLevel * CGFloat(heightMultiplier) * randomness

            animatedLevels[i] = min(max(targetLevel, Layout.initialLevel), 1.0)
        }
    }
}

#Preview("Low Level") {
    WaveformView(audioLevel: 0.2)
        .padding()
}

#Preview("Medium Level") {
    WaveformView(audioLevel: 0.5)
        .padding()
}

#Preview("High Level") {
    WaveformView(audioLevel: 0.9)
        .padding()
}
