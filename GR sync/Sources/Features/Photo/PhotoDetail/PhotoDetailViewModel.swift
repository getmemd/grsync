//
//  PhotoDetailViewModel.swift
//  GR sync
//
//  Created by Adilkhan Medeuyev on 14.09.2024.
//

import SwiftUI
import Kingfisher

@MainActor
class PhotoDetailViewModel: NSObject, ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError: Bool = false
    @Published var showingAlert: Bool = false
    @Published var showingSuccess: Bool = false
    
    let photo: Photo
    private var task: DownloadTask?
    private let imageService = ImageService()
    
    init(photo: Photo) {
        self.photo = photo
    }
    
    func cancelTasks() {
        task?.cancel()
        imageService.cancelAllTasks()
    }
    
    func loadPhoto() {
        isLoading = true
        guard let url = URL(string: photo.urlString) else { return }
        task = KingfisherManager.shared.retrieveImage(with: url) { [weak self] result in
            self?.isLoading = false
            switch result {
            case let .success(data):
                if let imageData = data.data() {
                    self?.image = UIImage(data: imageData)
                }
            case let .failure(error):
                self?.errorMessage = "Error: \(error.localizedDescription)"
                self?.showingError = true
            }
        }
    }
    
    func saveImage() {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }
            do {
                try await imageService.downloadAndSaveImages(photos: [photo])
                showingSuccess = true
            } catch {
                showingError = true
                errorMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
}
