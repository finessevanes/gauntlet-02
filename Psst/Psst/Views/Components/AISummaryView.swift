//
//  AISummaryView.swift
//  Psst
//
//  Created by Caleb (AI Agent) on PR #006
//  Modal view for displaying AI-generated conversation summaries
//

import SwiftUI

/// Modal view displaying a conversation summary with key points
struct AISummaryView: View {
    let summary: String
    let keyPoints: [String]
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Summary section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(summary)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Key points section
                    if !keyPoints.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Key Points")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ForEach(keyPoints, id: \.self) { point in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(.body)
                                        .foregroundColor(.accentColor)
                                    
                                    Text(point)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Conversation Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Dismiss") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        UIPasteboard.general.string = formatSummaryForClipboard()
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }
    
    /// Formats summary and key points for clipboard
    private func formatSummaryForClipboard() -> String {
        var text = "SUMMARY:\n\(summary)\n"
        
        if !keyPoints.isEmpty {
            text += "\nKEY POINTS:\n"
            for point in keyPoints {
                text += "• \(point)\n"
            }
        }
        
        return text
    }
}

#Preview {
    AISummaryView(
        summary: "Conversation covering 15 messages over the past few days. Main topics include workout planning, nutrition guidance, and progress updates.",
        keyPoints: [
            "Discussed injury concerns and modifications needed",
            "Reviewed workout plan and exercise progression",
            "Covered nutrition and dietary adjustments",
            "Tracked progress toward fitness goals"
        ],
        onDismiss: {}
    )
}

#Preview("Short Summary") {
    AISummaryView(
        summary: "Brief conversation covering 3 messages exchanged recently.",
        keyPoints: [],
        onDismiss: {}
    )
}

