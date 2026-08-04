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

    final class MockWatchListRepository: WatchListRepository {
        var pages: [Int: Page] = [:]
        var errors: [Int: Error] = [:]
        var delayNanosecondsByPage: [Int: UInt64] = [:]
        private(set) var callCount = 0
        private(set) var requestedPages: [Int] = []

        func fetchMovies(page: Int) async throws -> Page {
            callCount += 1
            requestedPages.append(page)
            if let delay = delayNanosecondsByPage[page], delay > 0 {
                try await Task.sleep(nanoseconds: delay)
            }
            if let error = errors[page] {
                throw error
            }
            guard let result = pages[page] else {
                Issue.record("Page \(page) not found")
                throw MockError.missingPage
            }
            return result
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

    let firstMovie = Movie(id: 1, title: "Toy Story", overview: "", posterPath: nil, releaseDate: nil)
    let secondMovie = Movie(id: 2, title: "Finding Nemo", overview: "", posterPath: nil, releaseDate: nil)
    let thirdMovie = Movie(id: 3, title: "Cars", overview: "", posterPath: nil, releaseDate: nil)

    @Test
    func testFetchMoviesSuccessContent() async {
        let repository = MockWatchListRepository()
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 1)
        let authRepository = MockAuthRepository()
        authRepository.accountId = 1

        let viewModel = WatchListViewModel(repository: repository, authRepository: authRepository)

        viewModel.fetchMovies()

        await waitForFinalState(viewModel: viewModel)

        switch viewModel.state {
        case .content(let movies, let error):
            #expect(movies == [firstMovie])
            #expect(error == nil)
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
        repository.errors[1] = MockError.failed
        let authRepository = MockAuthRepository()
        authRepository.accountId = 1

        let viewModel = WatchListViewModel(repository: repository, authRepository: authRepository)

        viewModel.fetchMovies()

        await waitForFinalState(viewModel: viewModel)

        switch viewModel.state {
        case .content(let movies, let error):
            #expect(movies.isEmpty)
            if case MockError.failed? = error {
                // ok
            } else {
                Issue.record("Unexpected error type")
            }
        default:
            Issue.record("Expected content state with error")
        }
    }

    @Test
    func testFetchMoreMoviesAppendsResults() async {
        let repository = MockWatchListRepository()
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 2)
        repository.pages[2] = Page(page: 2, results: [secondMovie], totalPages: 2)
        let authRepository = MockAuthRepository()
        authRepository.accountId = 1

        let viewModel = WatchListViewModel(repository: repository, authRepository: authRepository)

        viewModel.fetchMovies()
        await waitForFinalState(viewModel: viewModel)

        viewModel.fetchMoreMovies()
        await waitUntil {
            if case .content(let movies, _) = viewModel.state { return movies.count == 2 }
            return false
        }

        switch viewModel.state {
        case .content(let movies, let error):
            #expect(movies == [firstMovie, secondMovie])
            #expect(error == nil)
        default:
            Issue.record("Expected content state after loading more")
        }
    }

    @Test
    func testFetchMoreMoviesFailurePreservesExistingMovies() async {
        let repository = MockWatchListRepository()
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 2)
        repository.errors[2] = MockError.failed
        let authRepository = MockAuthRepository()
        authRepository.accountId = 1

        let viewModel = WatchListViewModel(repository: repository, authRepository: authRepository)

        viewModel.fetchMovies()
        await waitForFinalState(viewModel: viewModel)

        viewModel.fetchMoreMovies()
        await waitUntil {
            if case .content(_, let error) = viewModel.state { return error != nil }
            return false
        }

        switch viewModel.state {
        case .content(let movies, let error):
            #expect(movies == [firstMovie])
            #expect(error != nil)
        default:
            Issue.record("Expected content state with a non-blocking pagination error")
        }
    }

    @Test
    func testReloadLastPageRetriesTheFailedPageAndKeepsExistingMovies() async {
        let repository = MockWatchListRepository()
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 2)
        repository.errors[2] = MockError.failed
        let authRepository = MockAuthRepository()
        authRepository.accountId = 1

        let viewModel = WatchListViewModel(repository: repository, authRepository: authRepository)

        viewModel.fetchMovies()
        await waitForFinalState(viewModel: viewModel)

        viewModel.fetchMoreMovies()
        await waitUntil {
            if case .content(_, let error) = viewModel.state { return error != nil }
            return false
        }

        repository.errors[2] = nil
        repository.pages[2] = Page(page: 2, results: [secondMovie], totalPages: 2)

        viewModel.reloadLastPage()
        await waitUntil {
            if case .content(let movies, _) = viewModel.state { return movies.count == 2 }
            return false
        }

        switch viewModel.state {
        case .content(let movies, let error):
            #expect(movies == [firstMovie, secondMovie])
            #expect(error == nil)
        default:
            Issue.record("Expected content state after successful reload")
        }
        #expect(repository.requestedPages == [1, 2, 2])
    }

    @Test
    func testClearErrorKeepsMoviesAndRemovesError() async {
        let repository = MockWatchListRepository()
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 2)
        repository.errors[2] = MockError.failed
        let authRepository = MockAuthRepository()
        authRepository.accountId = 1

        let viewModel = WatchListViewModel(repository: repository, authRepository: authRepository)

        viewModel.fetchMovies()
        await waitForFinalState(viewModel: viewModel)

        viewModel.fetchMoreMovies()
        await waitUntil {
            if case .content(_, let error) = viewModel.state { return error != nil }
            return false
        }

        viewModel.clearError()

        switch viewModel.state {
        case .content(let movies, let error):
            #expect(movies == [firstMovie])
            #expect(error == nil)
        default:
            Issue.record("Expected content state after clearing error")
        }
    }

    @Test
    func testConcurrentFetchMoreMoviesDoesNotSkipOrDuplicatePages() async {
        let repository = MockWatchListRepository()
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 3)
        repository.pages[2] = Page(page: 2, results: [secondMovie], totalPages: 3)
        repository.pages[3] = Page(page: 3, results: [thirdMovie], totalPages: 3)
        repository.delayNanosecondsByPage[2] = 100_000_000
        let authRepository = MockAuthRepository()
        authRepository.accountId = 1

        let viewModel = WatchListViewModel(repository: repository, authRepository: authRepository)

        viewModel.fetchMovies()
        await waitForFinalState(viewModel: viewModel)

        // Simulates duplicate onAppear firing for the last cell before the first page-2
        // request has resolved.
        viewModel.fetchMoreMovies()
        viewModel.fetchMoreMovies()

        await waitUntil(timeout: 3) {
            if case .content(let movies, _) = viewModel.state { return movies.count == 2 }
            return false
        }

        guard case .content(let movies, let error) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(movies == [firstMovie, secondMovie])
        #expect(error == nil)

        // Page 2 must not have been skipped in favor of page 3.
        viewModel.fetchMoreMovies()
        await waitUntil(timeout: 3) {
            if case .content(let movies, _) = viewModel.state { return movies.count == 3 }
            return false
        }
        guard case .content(let finalMovies, _) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(finalMovies == [firstMovie, secondMovie, thirdMovie])
    }

    @Test
    func testRefreshMoviesResetsAndLoadsFirstPage() async {
        let repository = MockWatchListRepository()
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 1)
        let authRepository = MockAuthRepository()
        authRepository.accountId = 1

        let viewModel = WatchListViewModel(repository: repository, authRepository: authRepository)

        viewModel.refreshMovies()

        await waitForFinalState(viewModel: viewModel)

        switch viewModel.state {
        case .content(let movies, let error):
            #expect(movies == [firstMovie])
            #expect(error == nil)
        default:
            Issue.record("Expected content state after refresh")
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
        case .content(let movies, let error):
            #expect(movies == [firstMovie])
            #expect(error == nil)
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
        case .empty, .content, .unauthenticated:
            return
        }
    }
}

@MainActor
private func waitUntil(timeout: TimeInterval = 3, _ condition: () -> Bool) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() && Date() < deadline {
        await Task.yield()
    }
}
