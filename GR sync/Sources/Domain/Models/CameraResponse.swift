//
//  CameraResponse.swift
//  GR sync
//
//  Created by Adilkhan Medeuyev on 14.09.2024.
//

import Foundation

struct CameraResponse: Codable {
    let dirs: [Directory]
}

struct Directory: Codable {
    let name: String
    let files: [String]
}
