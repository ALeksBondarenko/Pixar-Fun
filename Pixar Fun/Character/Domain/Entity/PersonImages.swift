//
//  PersonImages.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 10.12.2025.
//

import Foundation

struct PersonImages: Codable {
    let profiles: [PersonImage]
}


struct PersonImage: Codable, Equatable {
    let filePath: String
    
    enum CodingKeys: String, CodingKey {
        case filePath = "file_path"
    }
}
