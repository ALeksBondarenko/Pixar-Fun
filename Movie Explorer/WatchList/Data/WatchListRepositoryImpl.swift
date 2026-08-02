//
//  FavoriteRepositoryImpl.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 25.01.2026.
//

import Foundation

class WatchListRepositoryImpl: WatchListRepository {

    private let service: WatchListServiceProtocol
    private let authRepository: AuthRepository

    init(service: WatchListServiceProtocol, authRepository: AuthRepository) {
        self.service = service
        self.authRepository = authRepository
    }

    func fetchMovies(page: Int) async throws -> Page {
        guard let accountId = authRepository.currentAccountId() else {
            throw AuthError.notAuthenticated
        }
        return try await service.fetchWatchListMovies(accountId: accountId, page: page)
    }
}
