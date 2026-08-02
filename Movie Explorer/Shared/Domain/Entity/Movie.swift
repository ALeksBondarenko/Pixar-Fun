//
//  Movie.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 07.12.2025.
//

import Foundation

struct Movie: Hashable, Codable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let releaseDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case releaseDate = "release_date"
        case posterPath = "poster_path"
    }
}
