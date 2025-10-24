//
//  ImageCacheService.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #1
//  Service for caching profile photos locally with LRU cleanup
//

import Foundation
import UIKit
 

/// Service for managing local image caching with size limits and LRU cleanup
/// Caches profile photos to disk for instant loading and reduced network usage
class ImageCacheService {
    
    // MARK: - Singleton
    
    static let shared = ImageCacheService()
    
    // MARK: - Properties
    
    /// Maximum cache size in bytes (50MB)
    private let maxCacheSizeBytes: Int = 50 * 1024 * 1024
    
    /// Cache directory URL
    private let cacheDirectory: URL
    
    /// FileManager for disk operations
    private let fileManager = FileManager.default
    
    /// Serial queue for thread-safe cache operations
    private let cacheQueue = DispatchQueue(label: "com.psst.imagecache", qos: .utility)
    
    /// In-memory cache for recently accessed images (faster access)
    private var memoryCache: NSCache<NSString, UIImage>
    
    // MARK: - Initialization
    
    private init() {
        // Set up cache directory
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cacheDir.appendingPathComponent("ProfilePhotos", isDirectory: true)
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Set up memory cache
        memoryCache = NSCache<NSString, UIImage>()
        memoryCache.countLimit = 50 // Cache up to 50 images in memory
        memoryCache.totalCostLimit = 10 * 1024 * 1024 // 10MB memory limit
        
    }
    
    // MARK: - Public Methods
    
    /// Caches an image for a user
    /// - Parameters:
    ///   - image: UIImage to cache
    ///   - userID: User ID to associate with the image
    func cacheProfilePhoto(_ image: UIImage, userID: String) async {
        await withCheckedContinuation { continuation in
            cacheQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                let sw = Stopwatch()
                // Cache in memory first
                self.memoryCache.setObject(image, forKey: userID as NSString)
                
                // Cache to disk
                let fileURL = self.cacheFileURL(for: userID)
                
                // Compress image for disk storage (JPEG at 0.8 quality)
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    Log.e("ImageCacheService", "Failed to convert image to JPEG userID=\(userID)")
                    continuation.resume()
                    return
                }
                
                do {
                    try imageData.write(to: fileURL)
                    
                    // Update access time metadata
                    try self.fileManager.setAttributes(
                        [.modificationDate: Date()],
                        ofItemAtPath: fileURL.path
                    )
                    
                    // Clean up cache if needed
                    Task {
                        await self.cleanupCacheIfNeeded()
                    }
                    
                } catch {
                    Log.e("ImageCacheService", "Failed to cache userID=\(userID): \(error.localizedDescription)")
                }
                
                continuation.resume()
            }
        }
    }
    
    /// Retrieves a cached image for a user
    /// - Parameter userID: User ID
    /// - Returns: Cached UIImage if available, nil otherwise
    func getCachedProfilePhoto(userID: String) async -> UIImage? {
        // Check memory cache first (fastest)
        if let cachedImage = memoryCache.object(forKey: userID as NSString) {
            return cachedImage
        }
        
        // Check disk cache
        return await withCheckedContinuation { continuation in
            cacheQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let fileURL = self.cacheFileURL(for: userID)
                
                guard self.fileManager.fileExists(atPath: fileURL.path) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Load image from disk
                guard let imageData = try? Data(contentsOf: fileURL),
                      let image = UIImage(data: imageData) else {
                    Log.e("ImageCacheService", "Failed to load cached image userID=\(userID)")
                    continuation.resume(returning: nil)
                    return
                }
                
                // Cache in memory for faster future access
                self.memoryCache.setObject(image, forKey: userID as NSString)
                
                // Update access time
                try? self.fileManager.setAttributes(
                    [.modificationDate: Date()],
                    ofItemAtPath: fileURL.path
                )
                
                continuation.resume(returning: image)
            }
        }
    }
    
    /// Invalidates cached image for a user
    /// - Parameter userID: User ID
    func invalidateProfilePhotoCache(userID: String) async {
        await withCheckedContinuation { continuation in
            cacheQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                let sw = Stopwatch()
                // Remove from memory cache
                self.memoryCache.removeObject(forKey: userID as NSString)
                
                // Remove from disk cache
                let fileURL = self.cacheFileURL(for: userID)
                
                if self.fileManager.fileExists(atPath: fileURL.path) {
                    do {
                        try self.fileManager.removeItem(at: fileURL)
                    } catch {
                        Log.e("ImageCacheService", "Failed to invalidate userID=\(userID): \(error.localizedDescription)")
                    }
                }
                
                continuation.resume()
            }
        }
    }
    
    /// Clears all cached images
    func clearAllCache() async {
        await withCheckedContinuation { continuation in
            cacheQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                // Clear memory cache
                self.memoryCache.removeAllObjects()
                
                // Clear disk cache
                do {
                    try self.fileManager.removeItem(at: self.cacheDirectory)
                    try self.fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
                } catch {
                    Log.e("ImageCacheService", "Failed to clear cache: \(error.localizedDescription)")
                }
                
                continuation.resume()
            }
        }
    }
    
    /// Gets the current cache size in bytes
    /// - Returns: Total cache size in bytes
    func getCacheSizeBytes() async -> Int {
        return await withCheckedContinuation { continuation in
            cacheQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: 0)
                    return
                }
                
                var totalSize = 0
                
                guard let enumerator = self.fileManager.enumerator(at: self.cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
                    continuation.resume(returning: 0)
                    return
                }
                
                for case let fileURL as URL in enumerator {
                    if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        totalSize += fileSize
                    }
                }
                
                continuation.resume(returning: totalSize)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Returns the file URL for a cached image
    /// - Parameter userID: User ID
    /// - Returns: File URL for the cached image
    private func cacheFileURL(for userID: String) -> URL {
        // Use sanitized userID as filename
        let sanitizedID = userID.replacingOccurrences(of: "/", with: "_")
        return cacheDirectory.appendingPathComponent("\(sanitizedID).jpg")
    }
    
    /// Cleans up cache if it exceeds the maximum size (LRU policy)
    private func cleanupCacheIfNeeded() async {
        await withCheckedContinuation { continuation in
            cacheQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                // Get all cached files with their access times
                guard let enumerator = self.fileManager.enumerator(
                    at: self.cacheDirectory,
                    includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
                ) else {
                    continuation.resume()
                    return
                }
                
                var files: [(url: URL, size: Int, accessDate: Date)] = []
                var totalSize = 0
                
                for case let fileURL as URL in enumerator {
                    if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
                       let fileSize = resourceValues.fileSize,
                       let accessDate = resourceValues.contentModificationDate {
                        files.append((url: fileURL, size: fileSize, accessDate: accessDate))
                        totalSize += fileSize
                    }
                }
                
                // Check if cleanup is needed
                guard totalSize > self.maxCacheSizeBytes else {
                    continuation.resume()
                    return
                }
                
                Log.i("ImageCacheService", "Cache size exceeded used=\(totalSize) max=\(self.maxCacheSizeBytes) starting cleanup")
                
                // Sort by access date (oldest first - LRU)
                files.sort { $0.accessDate < $1.accessDate }
                
                // Remove oldest files until cache size is under limit
                var currentSize = totalSize
                var removedCount = 0
                
                for file in files {
                    guard currentSize > self.maxCacheSizeBytes else { break }
                    
                    do {
                        try self.fileManager.removeItem(at: file.url)
                        currentSize -= file.size
                        removedCount += 1
                    } catch {
                        Log.e("ImageCacheService", "Failed to remove cache file: \(error.localizedDescription)")
                    }
                }
                
                Log.i("ImageCacheService", "Cleanup complete removed=\(removedCount) newSize=\(currentSize)")
                
                continuation.resume()
            }
        }
    }
}

