//
//  ImageService.swift
//  GR sync
//
//  Created by Adilkhan Medeuyev on 17.09.2024.
//

import UIKit
import Kingfisher
import Photos

final class ImageService: NSObject {
    private var imageContinuationKey = 0
    private var tasks: [DownloadTask?] = []

    // Отменяем все задачи загрузки
    func cancelAllTasks() {
        tasks.forEach { $0?.cancel() }
        tasks.removeAll()
    }
    
    // Загружаем и сохраняем изображения (RAW и обычные)
    func downloadAndSaveImages(photos: [Photo]) async throws {
        guard !photos.isEmpty else {
            throw NSError(domain: "ImageDownloadService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No photos available"])
        }
        let urls = photos.compactMap { URL(string: $0.urlString) }
        if photos.first?.fileType == .dng {
            try await downloadAndSaveRAWImages(from: urls)
        } else if photos.first?.fileType == .jpg {
            try await downloadAndSaveRegularImages(from: urls)
        }
    }

    // Загрузка и сохранение RAW-изображений
    private func downloadAndSaveRAWImages(from urls: [URL]) async throws {
        for url in urls {
            let savedUrl = try await downloadRAWFile(from: url)
            try await saveRAWImageToPhotoLibraryAndDelete(rawFileUrl: savedUrl)
        }
    }
    
    // Загрузка и сохранение обычных изображений
    private func downloadAndSaveRegularImages(from urls: [URL]) async throws {
        var loadedImages: [UIImage] = []
        for imageUrl in urls {
            loadedImages.append(try await downloadFile(from: imageUrl))
        }
        guard !loadedImages.isEmpty else {
            throw NSError(domain: "ImageDownloadService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No images were loaded"])
        }
        for image in loadedImages {
            try await savePhoto(image)
        }
        tasks.removeAll()
    }
    
    private func downloadFile(from url: URL) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let task = KingfisherManager.shared.retrieveImage(with: url) { result in
                switch result {
                case let .success(value):
                    continuation.resume(returning: value.image)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
            tasks.append(task)
        }
    }

    // Асинхронное сохранение фото в фотоальбом
    private func savePhoto(_ image: UIImage) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            objc_setAssociatedObject(image, &imageContinuationKey, continuation, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // Callback для завершения сохранения изображения
    @objc
    private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let continuation = objc_getAssociatedObject(image, &imageContinuationKey) as? CheckedContinuation<Void, Error> {
            objc_setAssociatedObject(image, &imageContinuationKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if let error = error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume()
            }
        }
    }

    // Загружаем RAW файл
    private func downloadRAWFile(from url: URL) async throws -> URL {
        let (tempUrl, _) = try await URLSession.shared.download(from: url)
        let destinationUrl = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
        
        do {
            try FileManager.default.moveItem(at: tempUrl, to: destinationUrl)
            return destinationUrl
        } catch {
            throw NSError(domain: "FileMoveError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to move file: \(error.localizedDescription)"])
        }
    }

    // Сохраняем RAW файл в фотобиблиотеку и после удаляем
    private func saveRAWImageToPhotoLibraryAndDelete(rawFileUrl: URL) async throws {
        try await saveRAWImageToPhotoLibrary(rawFileUrl: rawFileUrl)
        try FileManager.default.removeItem(at: rawFileUrl)
    }

    // Сохраняем RAW файл в фотоальбом
    private func saveRAWImageToPhotoLibrary(rawFileUrl: URL) async throws {
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
