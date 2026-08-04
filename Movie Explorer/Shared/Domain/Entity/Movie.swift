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

    init(id: Int, title: String, overview: String, posterPath: String?, releaseDate: Date?) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.releaseDate = releaseDate
    }

    // TMDB sometimes sends an empty string for release_date (e.g. unannounced movies).
    // The shared Decoder throws for that rather than guessing a date, so it's decoded
    // leniently here via `try?` instead of relying on decodeIfPresent, which would let
    // that throw fail the whole Movie (and therefore the whole page) instead of just
    // this field.
    init(from decoder: Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        overview = try container.decode(String.self, forKey: .overview)
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        releaseDate = try? container.decode(Date.self, forKey: .releaseDate)
    }
}
