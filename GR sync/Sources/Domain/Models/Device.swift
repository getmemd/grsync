//
//  Device.swift
//  GR sync
//
//  Created by Adilkhan Medeuyev on 14.09.2024.
//

import Foundation

enum DeviceConnectionStatus: String, Codable {
    case disconnected
    case connecting
    case connected
    case error
}

struct Device: Identifiable, Codable {
    var id = UUID()
    let ssid: String
    let password: String
    var status: DeviceConnectionStatus = .disconnected
}
