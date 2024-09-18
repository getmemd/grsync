//
//  PhotoListViewModel.swift
//  GR sync
//
//  Created by Adilkhan Medeuyev on 14.09.2024.
//

import SwiftUI
import Kingfisher

@MainActor
class PhotoListViewModel: NSObject, ObservableObject {
    @Published var photos: [Photo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError: Bool = false
    @Published var showingAlert: Bool = false
    @Published var selectedPhoto: Photo?
    @Published var showingSuccess: Bool = false
    @Published var selectedPhotos: Set<Photo> = []
    @Published var isSelectionMode: Bool = false
    
    private let fileType: FileType
    private let repository = PhotoRepository.shared
    private let imageService = ImageService()
    
    init(fileType: FileType) {
        self.fileType = fileType
    }
    
    func loadPhotos() async {
        isLoading = true
        do {
            let fetchedPhotos = try await repository.fetchPhotos(fileType: fileType)
            self.photos = fetchedPhotos.reversed()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Error: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    func saveSelectedPhotos() {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }
            do {
                try await imageService.downloadAndSaveImages(photos: Array(selectedPhotos))
                showingSuccess = true
                selectedPhotos.removeAll()
                isSelectionMode = false
            } catch {
                showingError = true
                errorMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    func cancelTasks() {
        imageService.cancelAllTasks()
    }
}
