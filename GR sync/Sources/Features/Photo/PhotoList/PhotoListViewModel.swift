//
//  PhotoListViewModel.swift
//  GR sync
//
//  Created by Adilkhan Medeuyev on 14.09.2024.
//

import SwiftUI
import Combine

@MainActor
class PhotoListViewModel: NSObject, ObservableObject {
    @Published var photos: [Photo] = []
    @Published var isLoading = false
    @Published var isProgress = false
    @Published var totalFiles: Int = 0
    @Published var downloadedFiles: Int = 0
    @Published var errorMessage: String?
    @Published var showingError: Bool = false
    @Published var showingAlert: Bool = false
    @Published var selectedPhoto: Photo?
    @Published var showingSuccess: Bool = false
    @Published var selectedPhotos: Set<Photo> = []
    @Published var isSelectionMode: Bool = false
    
    let imageService = ImageService()
    private let fileType: FileType
    private let repository = PhotoRepository.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(fileType: FileType) {
        self.fileType = fileType
        super.init()
        imageService.$downloadedCount
            .receive(on: DispatchQueue.main)
            .assign(to: \.downloadedFiles, on: self)
            .store(in: &cancellables)
        
        imageService.$totalCount
            .receive(on: DispatchQueue.main)
            .assign(to: \.totalFiles, on: self)
            .store(in: &cancellables)
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
        isProgress = true
        Task {
            defer {
                isProgress = false
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
}
