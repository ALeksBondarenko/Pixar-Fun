//
//  MovieDetailResponse.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 09.12.2025.
//

import Foundation

struct MovieDetails: Hashable, Codable {
    let id: Int
    let title: String
    let overview: String
    let genres: [Genres]
    let budget: Int
    let revenue: Int
    let status: String
    let releaseDate: Date
    let backdropPath: String
    let posterPath: String?
    let voteAverage: Double

    enum CodingKeys: String, CodingKey {
        case id, title, overview, genres, budget, revenue, status
        case releaseDate = "release_date"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
    }
}

struct Genres: Hashable, Codable {
    let id: Int
    let name: String
}
