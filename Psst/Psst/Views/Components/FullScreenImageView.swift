//
//  FullScreenImageView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #009
//  Full-screen image viewer with tap-to-dismiss and zoom functionality
//

import SwiftUI

struct FullScreenImageView: View {
    let imageURL: String
    let thumbnailURL: String?
    let width: Int?
    let height: Int?
    @Binding var isPresented: Bool
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var hasFailed = false
    
    private var aspectRatio: CGFloat? {
        guard let w = width, let h = height, w > 0, h > 0 else { return nil }
        return CGFloat(w) / CGFloat(h)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    dismissView()
                }
            
            if let image = image {
                // Full-screen image with zoom and pan
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            // Zoom gesture
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    let newScale = scale * delta
                                    scale = min(max(newScale, 0.5), 5.0) // Limit zoom range
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        if scale < 1.0 {
                                            scale = 1.0
                                            offset = .zero
                                        }
                                    }
                                },
                            
                            // Pan gesture
                            DragGesture()
                                .onChanged { value in
                                    let newOffset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                    offset = newOffset
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        if scale <= 1.0 {
                                            offset = .zero
                                        }
                                    }
                                }
                        )
                    )
                    .onTapGesture(count: 2) {
                        // Double tap to zoom
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if scale > 1.0 {
                                scale = 1.0
                                offset = .zero
                            } else {
                                scale = 2.0
                                offset = .zero
                            }
                        }
                    }
            } else if hasFailed {
                // Error state
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                    
                    Text("Failed to load image")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Button("Try Again") {
                        loadImage()
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(8)
                }
            } else {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("Loading...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: dismissView) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(.top, 50)
                    .padding(.trailing, 20)
                }
                
                Spacer()
            }
        }
        .onAppear {
            loadImage()
        }
        .onTapGesture {
            // Single tap to dismiss
            dismissView()
        }
    }
    
    private func loadImage() {
        isLoading = true
        hasFailed = false
        
        // Try to load from cache first
        if let cachedImage = loadFromCache() {
            DispatchQueue.main.async {
                self.image = cachedImage
                self.isLoading = false
            }
            return
        }
        
        // Load from network
        guard let url = URL(string: imageURL) else {
            hasFailed = true
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let loadedImage = UIImage(data: data) {
                    self.image = loadedImage
                    self.isLoading = false
                } else {
                    self.hasFailed = true
                    self.isLoading = false
                }
            }
        }.resume()
    }
    
    private func loadFromCache() -> UIImage? {
        guard let url = URL(string: imageURL) else { return nil }
        let request = URLRequest(url: url)
        
        // Use the same cache as RobustImageLoader
        let cache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: "image_cache"
        )
        
        guard let cachedResponse = cache.cachedResponse(for: request) else {
            return nil
        }
        
        return UIImage(data: cachedResponse.data)
    }
    
    private func dismissView() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

// MARK: - Preview

#Preview {
    FullScreenImageView(
        imageURL: "https://via.placeholder.com/800x600",
        thumbnailURL: nil,
        width: 800,
        height: 600,
        isPresented: .constant(true)
    )
}
