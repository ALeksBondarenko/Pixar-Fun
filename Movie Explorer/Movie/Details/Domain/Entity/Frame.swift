//
//  Frame.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 25.01.2026.
//


import Foundation

struct Frame: Equatable, Codable {
    let filePath: String
    
    enum CodingKeys: String, CodingKey {
        case filePath = "file_path"
    }
}
