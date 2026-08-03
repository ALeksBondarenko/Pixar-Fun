//
//  MoviesService.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 07.12.2025.
//

import Foundation

protocol MoviesServiceProtocol {
    
    func fetchMovies(page: Int) async throws -> Page

    func fetchMovies(page: Int, genre: Genres) async throws -> Page
}

class MoviesService: MoviesServiceProtocol {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func fetchMovies(page: Int) async throws -> Page {
        try await networkClient.request(
            .get("https://api.themoviedb.org/3/discover/movie"),
            queryParams: [
                Param(name: "include_adult", value: "false"),
                Param(name: "language", value: iso3166LanguageCode(Locale.current)),
                Param(name: "page", value: page),
                Param(name: "sort_by", value: "primary_release_date.desc"),
            ]
        )
    }
    
    func fetchMovies(page: Int, genre: Genres) async throws -> Page {
        try await networkClient.request(
            .get("https://api.themoviedb.org/3/discover/movie"),
            queryParams: [
                Param(name: "include_adult", value: "false"),
                Param(name: "language", value: iso3166LanguageCode(Locale.current)),
                Param(name: "page", value: page),
                Param(name: "sort_by", value: "primary_release_date.desc"),
                Param(name: "with_genres", value: genre.id)
            ]
        )
    }
}
