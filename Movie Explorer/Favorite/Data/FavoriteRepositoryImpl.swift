//
//  FavoriteRepositoryImpl.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 25.01.2026.
//

import Foundation

class FavoriteRepositoryImpl: FavoriteRepository {

    private let service: FavoriteServiceProtocol
    private let authRepository: AuthRepository

    init(service: FavoriteServiceProtocol, authRepository: AuthRepository) {
        self.service = service
        self.authRepository = authRepository
    }

    func fetchFavoriteMovies(page: Int) async throws -> Page {
        guard let accountId = authRepository.currentAccountId() else {
            throw AuthError.notAuthenticated
        }
        return try await service.fetchFavoriteMovies(accountId: accountId, page: page)
    }
}
