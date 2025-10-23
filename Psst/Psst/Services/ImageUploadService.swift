//
//  ImageUploadService.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #009
//  Service for image compression, thumbnail generation, and Firebase Storage uploads
//

import Foundation
import UIKit
import FirebaseStorage

/// Errors that can occur during image upload operations
enum ImageUploadError: LocalizedError {
    case invalidChatID
    case invalidImageData
    case compressionFailed
    case thumbnailGenerationFailed
    case networkUnavailable
    case uploadFailed(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidChatID:
            return "Invalid chat ID"
        case .invalidImageData:
            return "Invalid image data"
        case .compressionFailed:
            return "Image compression failed"
        case .thumbnailGenerationFailed:
            return "Thumbnail generation failed"
        case .networkUnavailable:
            return "Network unavailable"
        case .uploadFailed(let reason):
            return "Upload failed: \(reason)"
        }
    }
}

/// Service responsible for preparing and uploading chat images to Firebase Storage
final class ImageUploadService {
    
    // MARK: - Singleton
    static let shared = ImageUploadService()
    private init() {}
    
    // MARK: - Constants
    
    private enum CompressionSettings {
        static let maxSizeBytes = 2_000_000
        static let maxWidth: CGFloat = 1920
        static let maxHeight: CGFloat = 1080
        static let initialQuality: CGFloat = 0.85
        static let minQuality: CGFloat = 0.3
        static let qualityDecrement: CGFloat = 0.1
        static let maxAttempts = 10
        static let thumbnailMaxDimension: CGFloat = 150
        static let thumbnailQuality: CGFloat = 0.7
    }
    
    private enum StoragePath {
        static func fullImage(chatID: String, messageID: String) -> String {
            "chat-images/\(chatID)/\(messageID).jpg"
        }
        
        static func thumbnail(chatID: String, messageID: String) -> String {
            "chat-images/\(chatID)/thumbnails/\(messageID)_thumb.jpg"
        }
    }
    
    private enum RetrySettings {
        static let maxAttempts = 5
        static let baseDelaySeconds = 0.5
        static let storageErrorCode = -13010
    }
    
    // MARK: - Public API
    
    /// Compresses an image to fit under a size limit and within max dimensions
    /// - Parameters:
    ///   - image: Source UIImage
    ///   - maxSizeBytes: Maximum output size in bytes (default 2MB)
    ///   - maxWidth: Maximum width in pixels (default 1920)
    ///   - maxHeight: Maximum height in pixels (default 1080)
    /// - Returns: Compressed JPEG data
    func compressImage(_ image: UIImage,
                       maxSizeBytes: Int = CompressionSettings.maxSizeBytes,
                       maxWidth: CGFloat = CompressionSettings.maxWidth,
                       maxHeight: CGFloat = CompressionSettings.maxHeight) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let resized = self.resizeImageIfNeeded(image, maxWidth: maxWidth, maxHeight: maxHeight)
                var quality = CompressionSettings.initialQuality
                let minQuality = CompressionSettings.minQuality
                var bestData: Data?
                var attempts = 0
                
                while quality >= minQuality && attempts < CompressionSettings.maxAttempts {
                    attempts += 1
                    if let data = resized.jpegData(compressionQuality: quality) {
                        bestData = data
                        if data.count <= maxSizeBytes {
                            continuation.resume(returning: data)
                            return
                        }
                    }
                    quality -= CompressionSettings.qualityDecrement
                }
                
                if let bestData = bestData {
                    continuation.resume(returning: bestData)
                } else {
                    continuation.resume(throwing: ImageUploadError.compressionFailed)
                }
            }
        }
    }
    
    /// Generates a small thumbnail image (square-ish, preserving aspect ratio)
    /// - Parameters:
    ///   - imageData: Source image data
    ///   - maxDimension: Maximum width/height in pixels (default 150)
    /// - Returns: JPEG data for thumbnail
    func generateThumbnail(from imageData: Data, maxDimension: CGFloat = CompressionSettings.thumbnailMaxDimension) async throws -> Data {
        guard let image = UIImage(data: imageData) else {
            throw ImageUploadError.invalidImageData
        }
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let thumb = self.resizeImageToFit(image, maxDimension: maxDimension)
                guard let data = thumb.jpegData(compressionQuality: CompressionSettings.thumbnailQuality) else {
                    continuation.resume(throwing: ImageUploadError.thumbnailGenerationFailed)
                    return
                }
                continuation.resume(returning: data)
            }
        }
    }
    
    /// Uploads image data to Firebase Storage using a generated UUID filename
    /// - Parameters:
    ///   - imageData: JPEG image data to upload
    ///   - chatID: Chat identifier (folder)
    /// - Returns: Download URL string
    func uploadImage(imageData: Data, chatID: String) async throws -> String {
        let messageID = UUID().uuidString
        return try await uploadImage(imageData: imageData, chatID: chatID, messageID: messageID)
    }
    
    /// Uploads image data to Firebase Storage at a deterministic path
    /// - Parameters:
    ///   - imageData: JPEG image data to upload
    ///   - chatID: Chat identifier (folder)
    ///   - messageID: Message identifier (filename)
    /// - Returns: Download URL string
    func uploadImage(imageData: Data, chatID: String, messageID: String) async throws -> String {
        let filePath = StoragePath.fullImage(chatID: chatID, messageID: messageID)
        return try await uploadData(imageData, chatID: chatID, filePath: filePath)
    }
    
    /// Uploads thumbnail data to Firebase Storage under thumbnails subfolder
    /// - Parameters:
    ///   - thumbnailData: JPEG data for thumbnail
    ///   - chatID: Chat identifier
    ///   - messageID: Message identifier (base filename)
    /// - Returns: Download URL string
    func uploadThumbnail(thumbnailData: Data, chatID: String, messageID: String) async throws -> String {
        let filePath = StoragePath.thumbnail(chatID: chatID, messageID: messageID)
        return try await uploadData(thumbnailData, chatID: chatID, filePath: filePath)
    }
    
    // MARK: - Helpers
    
    /// Common upload logic for both full images and thumbnails
    /// - Parameters:
    ///   - data: JPEG image data to upload
    ///   - chatID: Chat identifier
    ///   - filePath: Storage path (generated via StoragePath enum)
    /// - Returns: Download URL string
    private func uploadData(_ data: Data, chatID: String, filePath: String) async throws -> String {
        guard !chatID.isEmpty else { throw ImageUploadError.invalidChatID }
        guard !data.isEmpty else { throw ImageUploadError.invalidImageData }
        
        guard NetworkMonitor.shared.isConnected else {
            throw ImageUploadError.networkUnavailable
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let fileRef = storageRef.child(filePath)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            _ = try await fileRef.putData(data, metadata: metadata)
            let url = try await fetchDownloadURLWithRetry(fileRef: fileRef, maxAttempts: RetrySettings.maxAttempts)
            return url.absoluteString
        } catch {
            throw ImageUploadError.uploadFailed(reason: error.localizedDescription)
        }
    }
    
    private func resizeImageIfNeeded(_ image: UIImage, maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage {
        let size = image.size
        let widthRatio = maxWidth / size.width
        let heightRatio = maxHeight / size.height
        let scale = min(1.0, min(widthRatio, heightRatio))
        if scale >= 1.0 { return image }
        let newSize = CGSize(width: floor(size.width * scale), height: floor(size.height * scale))
        return renderImage(image, targetSize: newSize)
    }
    
    private func resizeImageToFit(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        let scale = min(1.0, maxDimension / maxSide)
        if scale >= 1.0 { return image }
        let newSize = CGSize(width: floor(size.width * scale), height: floor(size.height * scale))
        return renderImage(image, targetSize: newSize)
    }
    
    private func renderImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    private func fetchDownloadURLWithRetry(fileRef: StorageReference, maxAttempts: Int) async throws -> URL {
        var attempt = 0
        var lastError: Error?
        while attempt < maxAttempts {
            attempt += 1
            do {
                return try await fileRef.downloadURL()
            } catch let error as NSError {
                lastError = error
                if error.domain == "FIRStorageErrorDomain" && error.code == RetrySettings.storageErrorCode {
                    if attempt < maxAttempts {
                        let delay = Double(attempt) * RetrySettings.baseDelaySeconds
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                }
                break
            }
        }
        throw lastError ?? ImageUploadError.uploadFailed(reason: "Unknown error")
    }
}


