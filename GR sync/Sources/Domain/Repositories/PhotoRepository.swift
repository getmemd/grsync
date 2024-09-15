//
//  PhotoRepository.swift
//  GR sync
//
//  Created by Adilkhan Medeuyev on 14.09.2024.
//

import Foundation

final class PhotoRepository {
    static let shared = PhotoRepository()
    
    private let baseUrl = "http://192.168.0.1/v1"
    
    func fetchPhotos(fileType: FileType) async throws -> [Photo] {
        guard let url = URL(string: "\(baseUrl)/photos") else {
            throw URLError(.badURL)
        }
        let request = URLRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        let cameraResponse = try JSONDecoder().decode(CameraResponse.self, from: data)
        var allPhotos: [Photo] = []
        for directory in cameraResponse.dirs {
            let files = directory.files.filter {
                $0.hasSuffix(fileType.rawValue)
            }
            for fileName in files {
                let photoURLString = "http://192.168.0.1/v1/photos/\(directory.name)/\(fileName)"
                let photo = Photo(
                    directory: directory.name,
                    fileName: fileName,
                    urlString: photoURLString,
                    fileType: fileType
                )
                allPhotos.append(photo)
            }
        }
        return allPhotos
    }
    
    func ping() async throws {
        guard let url = URL(string: "\(baseUrl)/ping") else {
            throw URLError(.badURL)
        }
        let request = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        print(data)
        print(response)
    }
}
