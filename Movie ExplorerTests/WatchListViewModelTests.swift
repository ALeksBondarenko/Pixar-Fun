//
//  WatchListViewModelTests.swift
//  Movie ExplorerTests
//
//  Created by Александр Бондаренко on 07.03.2026.
//

import Foundation
import Testing

@testable import Movie_Explorer

@MainActor
struct WatchListViewModelTests {

    class MockWatchListRepository: WatchListRepository {
        var pages: [Int: Page] = [:]
        var error: Error?

        func fetchMovies(page: Int) async throws -> Page {
            if let error = error {
                throw error
            }
            guard let page = pages[page] else {
                Issue.record("Page \(page) not found")
                throw MockError.missingPage
            }
            return page
        }
    }

    final class MockAuthRepository: AuthRepository {
        var accountId: Int?
        var loginError: Error?
        var loginCallCount = 0

        var isLoggedIn: Bool { accountId != nil }

        func currentAccountId() -> Int? {
            accountId
        }

        func login() async throws {
            loginCallCount += 1
            if let loginError {
                throw loginError
            }
            accountId = accountId ?? 1
        }

        func logout() {
            accountId = nil
        }
    }

    enum MockError: Error {
        case missingPage
        case failed
    }

    let firstMovie = Movie(
        id: 1,
        title: "Toy Story",
        overview: "",
        posterPath: nil,
        releaseDate: nil
    )
    let secondMovie = Movie(
        id: 2,
        title: "Finding Nemo",
        overview: "",
        posterPath: nil,
        releaseDate: nil
    )

    @Test
    func testFetchMoviesSuccessContent() async {
        let repository = MockWatchListRepository()
        repository.pages[1] = Page(
            page: 1,
            results: [firstMovie],
            totalPages: 1
        )

        let authRepository = MockAuthRepository()
        authRepository.accountId = 1

        let viewModel = WatchListViewModel(repository: repository, authRepository: authRepository)

        viewModel.fetchMovies()

        await waitForFinalState(viewModel: viewModel)

        switch viewModel.state {
        case .content(let movies):
            #expect(movies == [firstMovie])
        default:
            Issue.record("Expected content state")
        }
    }

    @Test
    func testFetchMoviesSuccessEmpty() async {
        let repository = MockWatchListRepository()
        repository.pages[1] = Page(page: 1, results: [], totalPages: 1)

        let authRepository = MockAuthRepository()
        authRepository.accountId = 1

        let viewModel = WatchListViewModel(repository: repository, authRepository: authRepository)

        viewModel.fetchMovies()

        await waitForFinalState(viewModel: viewModel)

        switch viewModel.state {
        case .empty:
            // ok
            break
        default:
            Issue.record("Expected empty state")
        }
    }

    @Test
    func testFetchMoviesFailureSetsError() async {
        let repository = MockWatchListRepository()
        repository.error = MockError.failed

        let authRepository = MockAuthRepository()
        authRepository.accountId = 1

        let viewModel = WatchListViewModel(repository: repository, authRepository: authRepository)

        viewModel.fetchMovies()

        await waitForFinalState(viewModel: viewModel)

        switch viewModel.state {
        case .error(let error):
            if case MockError.failed = error {
                // ok
            } else {
                Issue.record("Unexpected error type")
            }
        default:
            Issue.record("Expected error state")
        }
    }

    @Test
    func testFetchMoreMoviesAppendsResults() async {
        let repository = MockWatchListRepository()
        repository.pages[1] = Page(
            page: 1,
            results: [firstMovie],
            totalPages: 2
        )
        repository.pages[2] = Page(
            page: 2,
            results: [secondMovie],
            totalPages: 2
        )

        let authRepository = MockAuthRepository()
        authRepository.accountId = 1

        let viewModel = WatchListViewModel(repository: repository, authRepository: authRepository)

        viewModel.fetchMovies()
        await waitForFinalState(viewModel: viewModel)

        viewModel.fetchMoreMovies()
        await Task.yield()

        switch viewModel.state {
        case .content(let movies):
            #expect(movies == [firstMovie, secondMovie])
        default:
            Issue.record("Expected content state after loading more")
        }
    }

    @Test
    func testRefreshMoviesResetsAndLoadsFirstPage() async {
        let repository = MockWatchListRepository()
        repository.pages[1] = Page(
            page: 1,
            results: [firstMovie],
            totalPages: 1
        )

        let authRepository = MockAuthRepository()
        authRepository.accountId = 1

        let viewModel = WatchListViewModel(repository: repository, authRepository: authRepository)

        viewModel.refreshMovies()

        await waitForFinalState(viewModel: viewModel)

        switch viewModel.state {
        case .content(let movies):
            #expect(movies == [firstMovie])
        default:
            Issue.record("Expected content state after refresh")
        }
    }

    @Test
    func testReloadLastPageUsesCurrentPage() async {
        let repository = MockWatchListRepository()
        repository.pages[1] = Page(
            page: 1,
            results: [firstMovie],
            totalPages: 2
        )
        repository.pages[2] = Page(
            page: 2,
            results: [secondMovie],
            totalPages: 2
        )

        let authRepository = MockAuthRepository()
        authRepository.accountId = 1

        let viewModel = WatchListViewModel(repository: repository, authRepository: authRepository)

        viewModel.fetchMovies()
        await waitForFinalState(viewModel: viewModel)

        viewModel.fetchMoreMovies()
        await waitForFinalState(viewModel: viewModel)

        repository.pages[2] = Page(
            page: 2,
            results: [secondMovie, secondMovie],
            totalPages: 2
        )
        viewModel.reloadLastPage()
        await Task.yield()

        switch viewModel.state {
        case .content(let movies):
            #expect(movies == [firstMovie, secondMovie, secondMovie])
        default:
            Issue.record("Expected content state after reloadLastPage")
        }
    }

    @Test
    func testFetchMoviesShowsUnauthenticatedWhenLoggedOut() async {
        let repository = MockWatchListRepository()
        let authRepository = MockAuthRepository()

        let viewModel = WatchListViewModel(repository: repository, authRepository: authRepository)

        viewModel.fetchMovies()

        switch viewModel.state {
        case .unauthenticated:
            // ok
            break
        default:
            Issue.record("Expected unauthenticated state")
        }
    }

    @Test
    func testLoginSuccessTriggersFetch() async {
        let repository = MockWatchListRepository()
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 1)
        let authRepository = MockAuthRepository()

        let viewModel = WatchListViewModel(repository: repository, authRepository: authRepository)

        viewModel.login()
        await waitForFinalState(viewModel: viewModel)

        #expect(authRepository.loginCallCount == 1)
        switch viewModel.state {
        case .content(let movies):
            #expect(movies == [firstMovie])
        default:
            Issue.record("Expected content state after successful login")
        }
    }

    @Test
    func testLoginFailureStaysUnauthenticated() async {
        let repository = MockWatchListRepository()
        let authRepository = MockAuthRepository()
        authRepository.loginError = AuthError.cancelled

        let viewModel = WatchListViewModel(repository: repository, authRepository: authRepository)

        viewModel.login()
        await waitForFinalState(viewModel: viewModel)

        switch viewModel.state {
        case .unauthenticated:
            // ok
            break
        default:
            Issue.record("Expected unauthenticated state after failed login")
        }
    }
}

@MainActor
private func waitForFinalState(viewModel: WatchListViewModel) async {
    while true {
        switch viewModel.state {
        case .idle, .loading:
            await Task.yield()
        case .empty, .content, .error, .unauthenticated:
            return
        }
    }
}
