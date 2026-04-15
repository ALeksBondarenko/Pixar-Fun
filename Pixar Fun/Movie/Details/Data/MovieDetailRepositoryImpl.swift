//
//  MovieDetailRepositoryImpl.swift
//  Pixar Fun
//
//  Created by Александр Бондаренко on 25.01.2026.
//

import Foundation

final class MovieDetailRepositoryImpl: MovieDetailRepository {
    
    private let service: MovieDetailsServiceProtocol
    
    init(service: MovieDetailsServiceProtocol) {
        self.service = service
    }
    
    func getDetailsOfMovie(movieId: Int) async throws -> MovieDetails {
        try await service.getDetails(movieId: movieId)
    }
    
    func addToFavorites(movieId: Int) async throws -> Bool {
        try await service.changeFavoriteList(accountId: Environment.accountId, request: FavoriteRequest(mediaId: movieId, favorite: true)).success
    }
    
    func removeToFavorites(movieId: Int) async throws -> Bool {
        try await service.changeFavoriteList(accountId: Environment.accountId, request: FavoriteRequest(mediaId: movieId, favorite: false)).success
    }
    
    func addToWatchLater(movieId: Int) async throws -> Bool {
        try await service.changeWatchLater(accountId: Environment.accountId, request: WachListRequest(mediaId: movieId, watchlist: true)).success
    }
    
    func removeToWatchLater(movieId: Int) async throws -> Bool {
        try await service.changeWatchLater(accountId: Environment.accountId, request: WachListRequest(mediaId: movieId, watchlist: false)).success
    }
    
    
    func getMovieStatus(movieId: Int) async throws -> MovieStatus {
        try await service.getStatus(movieId: movieId)
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
}
