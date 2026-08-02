//
//  WatchListService.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 07.12.2025.
//

import Foundation

protocol WatchListServiceProtocol {

    func fetchWatchListMovies(accountId: Int, page: Int) async throws -> Page
}

class WatchListService: WatchListServiceProtocol {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func fetchWatchListMovies(accountId: Int, page: Int) async throws -> Page {
        try await networkClient.request(
            .get("https://api.themoviedb.org/3/account/\(accountId)/watchlist/movies"),
            queryParams: [
                Param(name: "language", value: iso3166LanguageCode(Locale.current)),
                Param(name: "page", value: page),
                Param(name: "sort_by", value: "created_at.asc"),
            ]
        )
    }
}
