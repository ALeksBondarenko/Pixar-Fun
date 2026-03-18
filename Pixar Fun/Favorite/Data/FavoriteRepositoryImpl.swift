//
//  FavoriteRepositoryImpl.swift
//  Pixar Fun
//
//  Created by Александр Бондаренко on 25.01.2026.
//

import Foundation

class FavoriteRepositoryImpl: FavoriteRepository {
    
    private let service: FavoriteServiceProtocol
    
    init(service: FavoriteServiceProtocol) {
        self.service = service
    }
    
    func fetchFavoriteMovies(page: Int) async throws -> Page {
        try await service.fetchFavoriteMovies(page: page)
    }
}
