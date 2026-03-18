//
//  FavoriteRepositoryImpl.swift
//  Pixar Fun
//
//  Created by Александр Бондаренко on 25.01.2026.
//

import Foundation

class WatchListRepositoryImpl: WatchListRepository {
    
    private let service: WatchListServiceProtocol
    
    init(service: WatchListServiceProtocol) {
        self.service = service
    }
    
    func fetchMovies(page: Int) async throws -> Page {
        try await service.fetchWatchListMovies(page: page)
    }
}
