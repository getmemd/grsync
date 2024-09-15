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
        NavigationView {
            Group {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                        ForEach(viewModel.photos) { photo in
                            NavigationLink(destination: PhotoDetailView(viewModel: .init(photo: photo))) {
                                KFImage(URL(string: "\(photo.urlString)?size=thumb"))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(5)
                            }
                        }
                    }
                }
                .navigationTitle("Photos")
            }
        }
        .blur(radius: viewModel.isLoading ? 10 : 0)
        .allowsHitTesting(!viewModel.isLoading)
        .task {
            await viewModel.loadPhotos()
        }
        .toast(isPresenting: $viewModel.showingAlert) {
            AlertToast(displayMode: .alert,
                       type: .error(.red),
                       title: "Error",
                       subTitle: viewModel.errorMessage)
        }
        .toast(isPresenting: $viewModel.isLoading) {
            AlertToast(displayMode: .banner(.slide), type: .loading, title: "Loading")
        }
    }
}

