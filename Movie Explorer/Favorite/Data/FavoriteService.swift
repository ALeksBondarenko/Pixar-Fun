//
//  Movie Explorer
//
//  Created by Александр Бондаренко on 07.12.2025.
//

import Foundation

protocol FavoriteServiceProtocol {

    func fetchFavoriteMovies(accountId: Int, page: Int) async throws -> Page
}

class FavoriteService: FavoriteServiceProtocol {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func fetchFavoriteMovies(accountId: Int, page: Int) async throws -> Page {
        try await networkClient.request(
            .get("https://api.themoviedb.org/3/account/\(accountId)/favorite/movies"),
            queryParams: [
                Param(name: "language", value: iso3166LanguageCode(Locale.current)),
                Param(name: "page", value: page),
                Param(name: "sort_by", value: "created_at.asc"),
            ]
        )
    }
}
