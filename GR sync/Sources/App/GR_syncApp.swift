//
//  GR_syncApp.swift
//  GR sync
//
//  Created by Adilkhan Medeuyev on 13.09.2024.
//

import SwiftUI

@main
struct GR_syncApp: App {
    var body: some Scene {
        WindowGroup {
            DevicesListView(viewModel: .init())
        }
    }
}
