//
//  ImageService.swift
//  GR sync
//
//  Created by Adilkhan Medeuyev on 17.09.2024.
//

import UIKit
import Kingfisher
import Photos
import Combine

final class ImageService: NSObject, ObservableObject {
    @Published var downloadedCount: Int = 0
    @Published var totalCount: Int = 0
    
    func downloadAndSaveImages(photos: [Photo]) async throws {
        guard !photos.isEmpty else {
            throw NSError(domain: "ImageDownloadService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No photos available"])
        }
        totalCount = photos.count
        downloadedCount = 0
        let urls = photos.compactMap { URL(string: $0.urlString) }
        try await downloadAndSaveImages(from: urls)
    }

    private func downloadAndSaveImages(from urls: [URL]) async throws {
        for url in urls {
            let savedUrl = try await downloadFile(from: url)
            try await saveImageToPhotoLibraryAndDelete(rawFileUrl: savedUrl)
            downloadedCount += 1
        }
    }
    
    private func downloadFile(from url: URL) async throws -> URL {
        let (tempUrl, _) = try await URLSession.shared.download(from: url)
        let destinationUrl = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
        do {
            try FileManager.default.moveItem(at: tempUrl, to: destinationUrl)
            return destinationUrl
        } catch {
            throw NSError(domain: "FileMoveError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to move file: \(error.localizedDescription)"])
        }
    }

    private func saveImageToPhotoLibraryAndDelete(rawFileUrl: URL) async throws {
        try await saveImageToPhotoLibrary(rawFileUrl: rawFileUrl)
        try FileManager.default.removeItem(at: rawFileUrl)
    }

    private func saveImageToPhotoLibrary(rawFileUrl: URL) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else {
                    continuation.resume(throwing: NSError(domain: "PhotoLibrary", code: 1, userInfo: [NSLocalizedDescriptionKey: "Access to photo library denied"]))
                    return
                }
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, fileURL: rawFileUrl, options: nil)
                }, completionHandler: { success, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                })
            }
        }
    }
}
