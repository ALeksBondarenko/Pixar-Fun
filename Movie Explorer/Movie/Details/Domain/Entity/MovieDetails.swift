//
//  MovieDetailResponse.swift
//  Movie Explorer
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
    let releaseDate: Date?
    let backdropPath: String?
    let posterPath: String?
    let voteAverage: Double

    enum CodingKeys: String, CodingKey {
        case id, title, overview, genres, budget, revenue, status
        case releaseDate = "release_date"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
    }

    init(
        id: Int,
        title: String,
        overview: String,
        genres: [Genres],
        budget: Int,
        revenue: Int,
        status: String,
        releaseDate: Date?,
        backdropPath: String?,
        posterPath: String?,
        voteAverage: Double
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.genres = genres
        self.budget = budget
        self.revenue = revenue
        self.status = status
        self.releaseDate = releaseDate
        self.backdropPath = backdropPath
        self.posterPath = posterPath
        self.voteAverage = voteAverage
    }

    // TMDB sometimes sends an empty string for release_date (e.g. unannounced movies).
    // The shared Decoder throws for that rather than guessing a date, so it's decoded
    // leniently here via `try?` instead of relying on decodeIfPresent, which would let
    // that throw fail the whole decode instead of just this field.
    init(from decoder: Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        overview = try container.decode(String.self, forKey: .overview)
        genres = try container.decode([Genres].self, forKey: .genres)
        budget = try container.decode(Int.self, forKey: .budget)
        revenue = try container.decode(Int.self, forKey: .revenue)
        status = try container.decode(String.self, forKey: .status)
        backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        voteAverage = try container.decode(Double.self, forKey: .voteAverage)
        releaseDate = try? container.decode(Date.self, forKey: .releaseDate)
    }
}

struct Genres: Hashable, Codable {
    let id: Int
    let name: String
}
