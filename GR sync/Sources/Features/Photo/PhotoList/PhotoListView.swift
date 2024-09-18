//
//  PhotoListView.swift
//  GR sync
//
//  Created by Adilkhan Medeuyev on 13.09.2024.
//

import SwiftUI
import Kingfisher
import AlertToast

struct PhotoListView: View {
    @StateObject var viewModel: PhotoListViewModel
    
    var body: some View {
        Group {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                    ForEach(viewModel.photos) { photo in
                        ZStack {
                            NavigationLink(destination: PhotoDetailView(viewModel: .init(photo: photo))) {
                                KFImage(URL(string: "\(photo.urlString)?size=thumb"))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(5)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(viewModel.isSelectionMode && viewModel.selectedPhotos.contains(photo) ? Color.blue : Color.clear, lineWidth: 3)
                                    )
                                    .overlay(
                                        viewModel.isSelectionMode && viewModel.selectedPhotos.contains(photo) ?
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 24))
                                            .position(x: 90, y: 10) : nil
                                    )
                            }
                            .disabled(viewModel.isSelectionMode)
                            .simultaneousGesture(TapGesture().onEnded {
                                if viewModel.isSelectionMode {
                                    toggleSelection(for: photo)
                                }
                            })
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(viewModel.isSelectionMode ? "Select Photos" : "Photos")
            .toolbar {
                if viewModel.isSelectionMode && !viewModel.isLoading {
                    ToolbarItem(placement: .topBarTrailing) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .foregroundColor(.blue)
                            .onTapGesture {
                                viewModel.showingAlert = true
                            }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.isSelectionMode.toggle()
                        if !viewModel.isSelectionMode {
                            viewModel.selectedPhotos.removeAll()
                        }
                    }) {
                        Text(viewModel.isSelectionMode ? "Done" : "Select")
                    }
                }
            }
            .alert("Save on device \(viewModel.selectedPhotos.count) files?", isPresented: $viewModel.showingAlert) {
                Button("Yes") {
                    viewModel.saveSelectedPhotos()
                }
                Button("No", role: .cancel) { }
            }
        }
        .blur(radius: viewModel.isLoading ? 10 : 0)
        .allowsHitTesting(!viewModel.isLoading)
        .task {
            await viewModel.loadPhotos()
        }
        .onDisappear {
            viewModel.cancelTasks()
        }
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
    
    private func toggleSelection(for photo: Photo) {
        if viewModel.selectedPhotos.contains(photo) {
            viewModel.selectedPhotos.remove(photo)
        } else {
            viewModel.selectedPhotos.insert(photo)
        }
    }
}
