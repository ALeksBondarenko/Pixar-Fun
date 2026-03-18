//
//  PixarApi.swift
//  Pixar Fan
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
}

class MovieDetailsService: MovieDetailsServiceProtocol {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    func getDetails(movieId: Int) async throws -> MovieDetails {
        try await networkClient.request(
            httpMethod: .GET,
            stringUrl: "https://api.themoviedb.org/3/movie/\(movieId)",
            queryParams: ["language":iso3166LanguageCode(Locale.current)]
        )
    }
    
    func getStatus(movieId: Int) async throws -> MovieStatus {
        try await networkClient.request(
            httpMethod: .GET,
            stringUrl: "https://api.themoviedb.org/3/movie/\(movieId)/account_states"
        )
    }
    
    func changeFavoriteList(accountId: Int, request: FavoriteRequest) async throws -> FavoriteResponse {
        try await networkClient.request(
            httpMethod: .POST,
            stringUrl: "https://api.themoviedb.org/3/account/\(accountId)/favorite",
            headers: [ "content-type": "application/json"],
            body: request,
        )
    }
    
    func changeWatchLater(accountId: Int, request: WachListRequest) async throws -> FavoriteResponse {
        try await networkClient.request(
            httpMethod: .POST,
            stringUrl: "https://api.themoviedb.org/3/account/\(accountId)/watchlist",
            headers: [ "content-type": "application/json"],
            body: request,
        )
    }
    
    func getVideos(movieId: Int) async throws -> VideosResponse {
        try await networkClient.request(
            httpMethod: .GET,
            stringUrl: "https://api.themoviedb.org/3/movie/\(movieId)/videos",
            queryParams: ["language":iso3166LanguageCode(Locale.current)]
        )
    }
    
    func getImages(movieId: Int) async throws -> ImagesResponse {
        try await networkClient.request(
            httpMethod: .GET,
            stringUrl: "https://api.themoviedb.org/3/movie/\(movieId)/images"
        )
    }
    
    func getCasts(movieId: Int) async throws -> CastsResponse {
        try await networkClient.request(
            httpMethod: .GET,
            stringUrl: "https://api.themoviedb.org/3/movie/\(movieId)/credits",
            queryParams: ["language":iso3166LanguageCode(Locale.current)]
        )
    }
}
