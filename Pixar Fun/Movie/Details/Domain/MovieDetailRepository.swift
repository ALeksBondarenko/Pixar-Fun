//
//  MovieDetailRepository.swift
//  Pixar Fun
//
//  Created by Александр Бондаренко on 25.01.2026.
//

import Foundation

protocol MovieDetailRepository {
    
    func getDetailsOfMovie(movieId: Int) async throws -> MovieDetails
    
    func addToFavorites(accountId: Int, movieId: Int) async throws -> Bool
    
    func removeToFavorites(accountId: Int, movieId: Int) async throws -> Bool
    
    func addToWatchLater(accountId: Int, movieId: Int) async throws -> Bool
    
    func removeToWatchLater(accountId: Int, movieId: Int) async throws -> Bool
    
    func getMovieStatus(movieId: Int) async throws -> MovieStatus
    
    func getImages(movieId: Int) async throws -> [Frame]
    
    func getVideos(movieId: Int) async throws -> [Video]
    
    func getCast(movieId: Int) async throws -> [Cast]
}
