//
//  ImageMessageView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #009
//  Displays an image message with loading and error states, preserving aspect ratio
//

import SwiftUI

struct ImageMessageView: View {
    let imageURL: String
    let thumbnailURL: String?
    let width: Int?
    let height: Int?
    
    private var aspectRatio: CGFloat? {
        if let w = width, let h = height, w > 0, h > 0 {
            return CGFloat(w) / CGFloat(h)
        }
        return nil
    }
    
    var body: some View {
        Group {
            if let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: 280, maxHeight: 280)
                            .clipped()
                            .cornerRadius(18)
                            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
                    case .failure:
                        errorView
                    @unknown default:
                        errorView
                    }
                }
            } else {
                errorView
            }
        }
    }
    
    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemGray6))
                .frame(maxWidth: 280, maxHeight: 280)
                .aspectRatio(aspectRatio ?? 1.33, contentMode: .fit)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
        }
    }
    
    private var errorView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemGray6))
                .frame(maxWidth: 280, maxHeight: 280)
                .aspectRatio(aspectRatio ?? 1.33, contentMode: .fit)
            
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                Text("Failed to load")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ImageMessageView(
            imageURL: "https://via.placeholder.com/600x400",
            thumbnailURL: nil,
            width: 600,
            height: 400
        )
    }
    .padding()
}


