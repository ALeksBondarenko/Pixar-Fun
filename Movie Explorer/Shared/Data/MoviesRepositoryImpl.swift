//
//  MoviesRepository.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 07.12.2025.
//

import Foundation


class MoviesRepositoryImpl: MoviesRepository {
    
    private let service: MoviesServiceProtocol
    
    init(service: MoviesServiceProtocol) {
        self.service = service
    }
    
    func fetchMovies(page: Int) async throws -> Page {
        try await service.fetchMovies(page: page)
    }
    
    func fetchMovies(page: Int, genre: Genres) async throws -> Page {
        try await service.fetchMovies(page: page, genre: genre)
    }
}
 
