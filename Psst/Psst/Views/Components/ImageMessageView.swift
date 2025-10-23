//
//  ImageMessageView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #009
//  Displays an image message with loading and error states, preserving aspect ratio
//

import SwiftUI

// MARK: - Image Message View

struct ImageMessageView: View {
    let imageURL: String
    let thumbnailURL: String?
    let width: Int?
    let height: Int?
    
    @State private var hasFailed = false
    @State private var useThumbnail = false
    
    private var aspectRatio: CGFloat? {
        guard let w = width, let h = height, w > 0, h > 0 else { return nil }
        return CGFloat(w) / CGFloat(h)
    }
    
    private var currentURL: String {
        useThumbnail ? (thumbnailURL ?? imageURL) : imageURL
    }
    
    var body: some View {
        Group {
            if let url = URL(string: currentURL) {
                RobustImageLoader(
                    url: url,
                    imageURL: currentURL,
                    aspectRatio: aspectRatio,
                    onSuccess: {
                        print("✅ [IMAGE LOAD] Image loaded successfully!")
                    },
                    onFailure: handleImageFailure
                )
            } else {
                ImageStateView.error(aspectRatio: aspectRatio)
                    .onAppear {
                        print("❌ [IMAGE LOAD] Invalid URL string: \(currentURL)")
                    }
            }
        }
    }
    
    private func handleImageFailure() {
        if !useThumbnail && thumbnailURL != nil {
            print("🔄 [IMAGE LOAD] Main image failed, trying thumbnail...")
            useThumbnail = true
        } else {
            print("❌ [IMAGE LOAD] Both main image and thumbnail failed")
            hasFailed = true
        }
    }
}

// MARK: - Robust Image Loader

struct RobustImageLoader: View {
    let url: URL
    let imageURL: String
    let aspectRatio: CGFloat?
    let onSuccess: (() -> Void)?
    let onFailure: (() -> Void)?
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var hasFailed = false
    @State private var retryCount = 0
    
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 2.0
    
    // Shared cache instance for all image loaders
    private static let sharedCache: URLCache = {
        URLCache(
            memoryCapacity: 50 * 1024 * 1024,  // 50MB memory cache
            diskCapacity: 200 * 1024 * 1024,   // 200MB disk cache
            diskPath: "image_cache"
        )
    }()
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: 250)
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .clipped()
                    .cornerRadius(12)
            } else if hasFailed {
                ImageStateView.error(aspectRatio: aspectRatio)
            } else {
                ImageStateView.loading(aspectRatio: aspectRatio)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        print("🖼️ [ROBUST LOADER] Starting to load image from URL: \(imageURL)")
        
        // Check cache first
        if let cachedImage = loadFromCache() {
            DispatchQueue.main.async {
                self.image = cachedImage
                self.isLoading = false
                self.hasFailed = false
                print("✅ [CACHE HIT] Image loaded from cache instantly!")
                onSuccess?()
            }
            return
        }
        
        print("🌐 [CACHE MISS] Loading from network...")
        loadFromNetwork()
    }
    
    private func loadFromCache() -> UIImage? {
        let request = URLRequest(url: url)
        guard let cachedResponse = Self.sharedCache.cachedResponse(for: request) else {
            return nil
        }
        
        print("💾 [CACHE HIT] Found cached image: \(cachedResponse.data.count) bytes")
        return UIImage(data: cachedResponse.data)
    }
    
    private func loadFromNetwork() {
        isLoading = true
        hasFailed = false
        
        let config = createURLSessionConfiguration()
        let session = URLSession(configuration: config)
        
        session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.handleNetworkResponse(data: data, response: response, error: error)
            }
        }.resume()
    }
    
    private func createURLSessionConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        config.timeoutIntervalForResource = 30.0
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        config.urlCache = Self.sharedCache
        return config
    }
    
    private func handleNetworkResponse(data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            print("❌ [ROBUST LOADER] Network error: \(error.localizedDescription)")
            handleFailure()
        } else if let httpResponse = response as? HTTPURLResponse {
            print("📊 [ROBUST LOADER] HTTP response: \(httpResponse.statusCode)")
            if httpResponse.statusCode == 200, let data = data, let image = UIImage(data: data) {
                print("✅ [ROBUST LOADER] Image loaded successfully")
                self.image = image
                self.isLoading = false
                onSuccess?()
            } else {
                print("❌ [ROBUST LOADER] HTTP error: \(httpResponse.statusCode)")
                handleFailure()
            }
        } else {
            print("❌ [ROBUST LOADER] Invalid response")
            handleFailure()
        }
    }
    
    private func handleFailure() {
        if retryCount < maxRetries {
            retryCount += 1
            print("🔄 [ROBUST LOADER] Retrying (\(retryCount)/\(maxRetries)) in \(retryDelay)s...")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                loadImage()
            }
        } else {
            print("❌ [ROBUST LOADER] Max retries reached, giving up")
            hasFailed = true
            isLoading = false
            onFailure?()
        }
    }
}

// MARK: - Image State Views

struct ImageStateView {
    static func loading(aspectRatio: CGFloat?) -> some View {
        ZStack {
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(maxWidth: 250)
                .aspectRatio(aspectRatio ?? 1.0, contentMode: .fit)
                .cornerRadius(12)
            VStack(spacing: 8) {
                ProgressView()
                Text("Loading...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    static func error(aspectRatio: CGFloat?) -> some View {
        ZStack {
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(maxWidth: 250)
                .aspectRatio(aspectRatio ?? 1.0, contentMode: .fit)
                .cornerRadius(12)
            VStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                Text("Failed to load")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

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