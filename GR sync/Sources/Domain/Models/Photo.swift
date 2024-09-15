//
//  Photo.swift
//  GR sync
//
//  Created by Adilkhan Medeuyev on 14.09.2024.
//

import Foundation

enum FileType: String {
    case jpg = ".JPG"
    case dng = ".DNG"
}

struct Photo: Identifiable {
    let id = UUID()
    let directory: String
    let fileName: String
    let urlString: String
    var fileType: FileType
}
