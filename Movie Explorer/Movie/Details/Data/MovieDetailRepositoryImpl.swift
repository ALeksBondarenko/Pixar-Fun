//
//  MovieDetailRepositoryImpl.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 25.01.2026.
//

import Foundation

final class MovieDetailRepositoryImpl: MovieDetailRepository {

    private let service: MovieDetailsServiceProtocol
    private let authRepository: AuthRepository

    init(service: MovieDetailsServiceProtocol, authRepository: AuthRepository) {
        self.service = service
        self.authRepository = authRepository
    }

    func getDetailsOfMovie(movieId: Int) async throws -> MovieDetails {
        try await service.getDetails(movieId: movieId)
    }

    func addToFavorites(movieId: Int) async throws -> Bool {
        let accountId = try requireAccountId()
        return try await service.changeFavoriteList(accountId: accountId, request: FavoriteRequest(mediaId: movieId, favorite: true)).success
    }

    func removeToFavorites(movieId: Int) async throws -> Bool {
        let accountId = try requireAccountId()
        return try await service.changeFavoriteList(accountId: accountId, request: FavoriteRequest(mediaId: movieId, favorite: false)).success
    }

    func addToWatchLater(movieId: Int) async throws -> Bool {
        let accountId = try requireAccountId()
        return try await service.changeWatchLater(accountId: accountId, request: WachListRequest(mediaId: movieId, watchlist: true)).success
    }

    func removeToWatchLater(movieId: Int) async throws -> Bool {
        let accountId = try requireAccountId()
        return try await service.changeWatchLater(accountId: accountId, request: WachListRequest(mediaId: movieId, watchlist: false)).success
    }


    func getMovieStatus(movieId: Int) async throws -> MovieStatus {
        _ = try requireAccountId()
        return try await service.getStatus(movieId: movieId)
    }

    private func requireAccountId() throws -> Int {
        guard let accountId = authRepository.currentAccountId() else {
            throw AuthError.notAuthenticated
        }
        return accountId
    }
    
    func getImages(movieId: Int) async throws -> [Frame] {
        try await service.getImages(movieId: movieId).backdrops
    }
    
    func getVideos(movieId: Int) async throws -> [Video] {
        try await service.getVideos(movieId: movieId).results
    }
    
    func getCast(movieId: Int) async throws -> [Cast] {
        try await service.getCasts(movieId: movieId).cast
    }
    
    func getSimilar(movieId: Int, page: Int) async throws -> Page {
        try await service.getSimilar(movieId: movieId, page: page)
    }
    
}
