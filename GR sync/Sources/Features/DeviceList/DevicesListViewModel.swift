//
//  DevicesListViewModel.swift
//  GR sync
//
//  Created by Adilkhan Medeuyev on 14.09.2024.
//

import Foundation
import Combine
import NetworkExtension

class DevicesListViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var showingAlert = false
    @Published var showingConnectionView = false
    @Published var devices: [Device] = []

    private let devicesKey = "savedDevices"
    private let photoRepository: PhotoRepository = .shared
    
    init() {
        loadDevices()
    }
    
    func addDevice(_ device: Device) {
        devices.append(device)
        saveDevices()
        showingConnectionView = false
    }
    
    func removeDevice(at offsets: IndexSet) {
        devices.remove(atOffsets: offsets)
        saveDevices()
    }
    
    private func saveDevices() {
        if let encoded = try? JSONEncoder().encode(devices) {
            UserDefaults.standard.set(encoded, forKey: devicesKey)
        }
    }
    
    private func loadDevices() {
        if let savedDevices = UserDefaults.standard.data(forKey: devicesKey),
           let decodedDevices = try? JSONDecoder().decode([Device].self, from: savedDevices) {
            devices = decodedDevices.map { device in
                var modifiedDevice = device
                modifiedDevice.status = .disconnected
                return modifiedDevice
            }
        }
    }
    
    func connectToDevice(_ device: Device) {
        guard let index = devices.firstIndex(where: { $0.id == device.id }) else { return }
        devices[index].status = .connecting
        let hotspotConfiguration = NEHotspotConfiguration(ssid: device.ssid, passphrase: "password123", isWEP: false)
        hotspotConfiguration.joinOnce = true
        let hotspotManager = NEHotspotConfigurationManager.shared
        Task {
            do {
                try await hotspotManager.apply(hotspotConfiguration)
                try await photoRepository.ping()
                devices[index].status = .connected
            } catch {
                errorMessage = error.localizedDescription
                devices[index].status = .error
                showingAlert = true
            }
        }
    }
}
