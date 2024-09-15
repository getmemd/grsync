//
//  PhotoDetailView.swift
//  GR sync
//
//  Created by Adilkhan Medeuyev on 13.09.2024.
//

import SwiftUI
import Kingfisher
import SwiftUIImageViewer
import AlertToast

struct PhotoDetailView: View {
    @StateObject var viewModel: PhotoDetailViewModel
    
    var body: some View {
        VStack {
            Spacer()
            if let image = viewModel.image {
                SwiftUIImageViewer(image: Image(uiImage: image))
                    .blur(radius: viewModel.isLoading ? 10 : 0)
            }
            Spacer()
        }
        .task {
            viewModel.loadPhoto()
        }
        .onDisappear {
            viewModel.cancelTask()
        }
        .navigationTitle(viewModel.photo.fileName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: "square.and.arrow.down.fill")
                    .foregroundColor(.blue)
                    .onTapGesture {
                        viewModel.showingAlert = true
                    }
                    .alert("Save on device?", isPresented: $viewModel.showingAlert) {
                        Button("Yes") {
                            viewModel.writeToPhotoAlbum()
                        }
                        Button("No", role: .cancel) { }
                    }
            }
        }
        .allowsHitTesting(!viewModel.isLoading)
        .toast(isPresenting: $viewModel.showingError) {
            AlertToast(displayMode: .alert,
                       type: .error(.red),
                       title: "Error",
                       subTitle: viewModel.errorMessage)
        }
        .toast(isPresenting: $viewModel.isLoading) {
            AlertToast(displayMode: .banner(.slide), type: .loading, title: "Loading")
        }
        .toast(isPresenting: $viewModel.showingSuccess) {
            AlertToast(displayMode: .banner(.slide), type: .complete(.green), title: "Saved")
        }
    }
}
