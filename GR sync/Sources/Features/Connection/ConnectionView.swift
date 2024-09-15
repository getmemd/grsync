//
//  ConnectionViewModel.swift
//  GR sync
//
//  Created by Adilkhan Medeuyev on 13.09.2024.
//

import SwiftUI
import AlertToast

struct ConnectionView: View {
    @State var ssid: String = ""
    @State var password: String = ""
    
    var onAdd: (String, String) -> Void
    
    var body: some View {
        ZStack {
            VStack {
                Text("Connection to camera")
                    .font(.largeTitle)
                    .padding(.bottom, 40)
                Text("Enter SSID and password")
                    .padding(.bottom, 20)
                TextField("SSID", text: $ssid)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Button(action: {
                    onAdd(ssid, password)
                }) {
                    Text("Add")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(ssid.isEmpty || password.isEmpty)
                .padding(.top)
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ConnectionView(onAdd: { _,_  in })
}
