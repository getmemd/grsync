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
    private var continuation: CheckedContinuation<Void, any Error>?
    private var tasks: [DownloadTask?] = []

    // Отменяем все задачи загрузки
    func cancelAllTasks() {
        tasks.forEach { $0?.cancel() }
        tasks.removeAll()
    }
    
    // Загружаем и сохраняем изображения (RAW и обычные)
    func downloadAndSaveImages(photos: [Photo], completion: @escaping (Result<Void, Error>) -> Void) {
        guard !photos.isEmpty else {
            completion(.failure(NSError(domain: "ImageDownloadService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No photos available"])))
            return
        }

        let urls = photos.compactMap { URL(string: $0.urlString) }

        if photos.first?.fileType == .dng {
            Task {
                do {
                    try await downloadAndSaveRAWImages(from: urls)
                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
            }
        } else {
            downloadAndSaveRegularImages(from: urls, completion: completion)
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
    private func downloadAndSaveRegularImages(from urls: [URL], completion: @escaping (Result<Void, Error>) -> Void) {
        var loadedImages: [UIImage] = []
        let group = DispatchGroup()

        for imageUrl in urls {
            group.enter()
            let task = KingfisherManager.shared.retrieveImage(with: imageUrl) { result in
                defer { group.leave() }
                switch result {
                case let .success(value):
                    loadedImages.append(value.image)
                case let .failure(error):
                    completion(.failure(error))
                    return
                }
            }
            tasks.append(task)
        }
        
        group.notify(queue: .main) { [weak self] in
            guard !loadedImages.isEmpty else {
                completion(.failure(NSError(domain: "ImageDownloadService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No images were loaded"])))
                return
            }
            self?.saveImagesToPhotoAlbum(images: loadedImages, completion: completion)
        }
    }

    // Сохраняем фото в фотоальбом
    private func saveImagesToPhotoAlbum(images: [UIImage], completion: @escaping (Result<Void, Error>) -> Void) {
        defer { tasks.removeAll() }
        Task {
            do {
                for image in images {
                    try await savePhoto(image)
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // Асинхронное сохранение фото в фотоальбом
    private func savePhoto(_ image: UIImage) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }

    // Callback для завершения сохранения изображения
    @objc
    private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            continuation?.resume(throwing: error)
        } else {
            continuation?.resume()
        }
        continuation = nil
    }

    // Загружаем RAW файл
    func downloadRAWFile(from url: URL) async throws -> URL {
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
    func saveRAWImageToPhotoLibraryAndDelete(rawFileUrl: URL) async throws {
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
