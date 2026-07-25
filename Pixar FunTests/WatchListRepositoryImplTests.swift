//
//  WatchListRepositoryImplTests.swift
//  Pixar FunTests
//
//  Created by Александр Бондаренко on 07.03.2026.
//

import Testing
@testable import Pixar_Fun
import Foundation

@MainActor
struct WatchListRepositoryImplTests {

    final class MockWatchListService: WatchListServiceProtocol {

        var error: Error?

        var result: Page?
        var accountId: Int?
        var page: Int?

        func fetchWatchListMovies(accountId: Int, page: Int) async throws -> Page {
            if let error = error {
                throw error
            }
            self.accountId = accountId
            self.page = page

            guard let result = result else {
                Issue.record("result is not set")
                throw MockError.resultNotSet
            }
            return result
        }
    }

    final class MockAuthRepository: AuthRepository {
        var accountId: Int?

        var isLoggedIn: Bool { accountId != nil }

        func currentAccountId() -> Int? {
            accountId
        }

        func login() async throws {
            accountId = accountId ?? 1
        }

        func logout() {
            accountId = nil
        }
    }

    enum MockError: Error {
        case resultNotSet
        case failed
    }

    @Test
    func testFetchMoviesDelegatesToService() async {
        let service = MockWatchListService()
        let authRepository = MockAuthRepository()
        authRepository.accountId = 42
        let movie = Movie(id: 1, title: "Toy Story", overview: "", posterPath: nil, releaseDate: nil)
        let expectedPage = Page(page: 1, results: [movie], totalPages: 2)
        service.result = expectedPage

        let repository = WatchListRepositoryImpl(service: service, authRepository: authRepository)

        do {
            let result = try await repository.fetchMovies(page: 1)

            #expect(result == expectedPage)
            #expect(service.accountId == 42)
            #expect(service.page == 1)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func testFetchMoviesPropagatesServiceError() async {
        let service = MockWatchListService()
        let authRepository = MockAuthRepository()
        authRepository.accountId = 42
        service.error = MockError.failed
        let repository = WatchListRepositoryImpl(service: service, authRepository: authRepository)

        do {
            _ = try await repository.fetchMovies(page: 1)
            Issue.record("Expected error to be thrown")
        } catch {
            if case MockError.failed = error {
                // ok
            } else {
                Issue.record("Unexpected error type: \(error)")
            }
        }
    }

    @Test
    func testFetchMoviesThrowsWhenNotAuthenticated() async {
        let service = MockWatchListService()
        let authRepository = MockAuthRepository()
        let repository = WatchListRepositoryImpl(service: service, authRepository: authRepository)

        do {
            _ = try await repository.fetchMovies(page: 1)
            Issue.record("Expected AuthError.notAuthenticated to be thrown")
        } catch AuthError.notAuthenticated {
            // ok
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }

        #expect(service.accountId == nil)
        #expect(service.page == nil)
    }
}
