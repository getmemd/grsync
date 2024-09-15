//
//  PhotoListViewModel.swift
//  GR sync
//
//  Created by Adilkhan Medeuyev on 14.09.2024.
//

import SwiftUI

@MainActor
class PhotoListViewModel: ObservableObject {
    @Published var photos: [Photo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingAlert: Bool = false
    @Published var selectedPhoto: Photo?
    
    private let fileType: FileType
    private let repository = PhotoRepository.shared
    
    init(fileType: FileType) {
        self.fileType = fileType
    }
    
    func loadPhotos() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetchedPhotos = try await repository.fetchPhotos(fileType: fileType)
            self.photos = fetchedPhotos
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Error: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}
