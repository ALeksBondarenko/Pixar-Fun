//
//  PixarApi.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 07.12.2025.
//

import Foundation

protocol MoviesServiceProtocol {
    
    func fetchPixarMovies(page: Int, genre: Genres?) async throws -> Page
}

class MoviesService: MoviesServiceProtocol {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    func fetchPixarMovies(page: Int, genre: Genres?) async throws -> Page {
        try await networkClient.request(
            httpMethod: .GET,
            stringUrl: "https://api.themoviedb.org/3/discover/movie",
            queryParams: [
                "include_adult": "false",
                "language":iso3166LanguageCode(Locale.current),
                "page":"\(page)",
                "sort_by" : "primary_release_date.desc",
                "with_companies" : "3",
                "with_genres": genre?.id ?? "16",
            ]
        )
    }
}
