//
//  OptionsListView.swift
//  GR sync
//
//  Created by Adilkhan Medeuyev on 14.09.2024.
//

import SwiftUI

struct OptionsListView: View {
    var body: some View {
        List {
            NavigationLink("JPG files", destination: PhotoListView(viewModel: .init(fileType: .jpg)))
            NavigationLink("DNG files", destination: PhotoListView(viewModel: .init(fileType: .dng)))
        }
        .navigationTitle("Options")
    }
}

#Preview {
    OptionsListView()
}
