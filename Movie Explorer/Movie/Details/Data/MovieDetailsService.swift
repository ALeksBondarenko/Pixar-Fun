//
//  Movie Explorer
//
//  Created by Александр Бондаренко on 07.12.2025.
//

import Foundation

protocol MovieDetailsServiceProtocol {
    
    func getDetails(movieId: Int) async throws -> MovieDetails
    
    func getStatus(movieId: Int) async throws -> MovieStatus
    
    func changeFavoriteList(accountId: Int, request: FavoriteRequest) async throws -> FavoriteResponse
    
    func changeWatchLater(accountId: Int, request: WachListRequest) async throws -> FavoriteResponse
    
    func getVideos(movieId: Int) async throws -> VideosResponse
    
    func getImages(movieId: Int) async throws -> ImagesResponse
    
    func getCasts(movieId: Int) async throws -> CastsResponse
    
    func getSimilar(movieId: Int, page: Int) async throws -> Page
}

class MovieDetailsService: MovieDetailsServiceProtocol {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    func getDetails(movieId: Int) async throws -> MovieDetails {
        try await networkClient.request(
            .get("https://api.themoviedb.org/3/movie/\(movieId)"),
            queryParams: [Param(name: "language", value: iso3166LanguageCode(Locale.current))]
        )
    }
    
    func getStatus(movieId: Int) async throws -> MovieStatus {
        try await networkClient.request(.get("https://api.themoviedb.org/3/movie/\(movieId)/account_states"))
    }
    
    func changeFavoriteList(accountId: Int, request: FavoriteRequest) async throws -> FavoriteResponse {
        try await networkClient.request(
            .post("https://api.themoviedb.org/3/account/\(accountId)/favorite"),
            headers: [.contentType(.json)],
            body: request,
        )
    }
    
    func changeWatchLater(accountId: Int, request: WachListRequest) async throws -> FavoriteResponse {
        try await networkClient.request(
            .post("https://api.themoviedb.org/3/account/\(accountId)/watchlist"),
            headers: [.contentType(.json)],
            body: request,
        )
    }
    
    func getVideos(movieId: Int) async throws -> VideosResponse {
        try await networkClient.request(
            .get("https://api.themoviedb.org/3/movie/\(movieId)/videos"),
            queryParams: [Param(name: "language", value: iso3166LanguageCode(Locale.current))]
        )
    }
    
    func getImages(movieId: Int) async throws -> ImagesResponse {
        try await networkClient.request(.get("https://api.themoviedb.org/3/movie/\(movieId)/images"))
    }
    
    func getCasts(movieId: Int) async throws -> CastsResponse {
        try await networkClient.request(
            .get("https://api.themoviedb.org/3/movie/\(movieId)/credits"),
            queryParams: [Param(name: "language", value: iso3166LanguageCode(Locale.current))]
        )
    }
    
    func getSimilar(movieId: Int, page: Int) async throws -> Page {
        try await networkClient.request(
            .get("https://api.themoviedb.org/3/movie/\(movieId)/similar"),
            queryParams: [
                Param(name: "page", value: page),
                Param(name: "language", value: iso3166LanguageCode(Locale.current)),
            ]
        )
    }
}
