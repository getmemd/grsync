//
//  DeviceListView.swift
//  GR sync
//
//  Created by Adilkhan Medeuyev on 14.09.2024.
//

import SwiftUI
import AlertToast

struct DevicesListView: View {
    @StateObject var viewModel = DevicesListViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.devices.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                        Text("No devices added")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Click '+' to add a new device.")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    .multilineTextAlignment(.center)
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.devices) { device in
                            HStack {
                                Button(action: {
                                    viewModel.connectToDevice(device)
                                }) {
                                    HStack {
                                        Image(systemName: "wifi")
                                            .foregroundColor(wifiIconColor(for: device.status))
                                            .font(.system(size: 24, weight: .medium))
                                        VStack(alignment: .leading) {
                                            Text("SSID: \(device.ssid)")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text(connectionStatusText(for: device.status))
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                        Spacer()
                                        if device.status == .connecting {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        }
                                    }
                                    .padding()
                                    .background(
                                        LinearGradient(gradient: Gradient(colors: [Color.teal, Color.blue]), startPoint: .leading, endPoint: .trailing)
                                    )
                                    .cornerRadius(15)
                                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                                }
                                .animation(.easeInOut(duration: 0.3), value: device.status)

                            }
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: viewModel.removeDevice)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Devices")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showingConnectionView = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingConnectionView) {
                ConnectionViewWrapper(viewModel: viewModel)
            }
        }
    }

    func wifiIconColor(for status: DeviceConnectionStatus) -> Color {
        switch status {
        case .connecting:
            return .yellow
        case .connected:
            return .green
        case .error:
            return .red
        case .disconnected:
            return .gray
        }
    }
    
    func connectionStatusText(for status: DeviceConnectionStatus) -> String {
        switch status {
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .error:
            return "Connection Failed"
        case .disconnected:
            return "Not Connected"
        }
    }
}

#Preview {
    DevicesListView(viewModel: .init())
}
