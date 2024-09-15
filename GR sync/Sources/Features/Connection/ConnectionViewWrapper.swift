//
//  ConnectionViewWrapper.swift
//  GR sync
//
//  Created by Adilkhan Medeuyev on 14.09.2024.
//

import SwiftUI

struct ConnectionViewWrapper: View {
    @ObservedObject var viewModel: DevicesListViewModel
    
    var body: some View {
        ConnectionView { ssid, password in
            viewModel.addDevice(.init(id: UUID(), ssid: ssid, password: password))
        }
    }
}
