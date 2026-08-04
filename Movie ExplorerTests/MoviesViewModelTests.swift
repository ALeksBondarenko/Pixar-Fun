//
//  MoviesViewModelTests.swift
//  Movie ExplorerTests
//
//  Created by Александр Бондаренко on 25.01.2026.
//

import Testing
@testable import Movie_Explorer
import Foundation

@MainActor
struct MoviesViewModelTests {
    let firstMovie = Movie(id: 1, title: "Toy Story", overview: "", posterPath: "/posterPath.jpg", releaseDate: Date())
    let secondMovie = Movie(id: 2, title: "Hoppers", overview: "", posterPath: "/posterPath.jpg", releaseDate: Date())
                                
    final class MockMoviesRepository: MoviesRepository {

        var pages = [Int: Page]()
        var errors: [Int: Error] = [:]
        var delayNanosecondsByPage: [Int: UInt64] = [:]
        var error: Error?
        private(set) var requestedPages: [Int] = []

        func fetchMovies(page: Int) async throws -> Page {
            requestedPages.append(page)
            if let delay = delayNanosecondsByPage[page], delay > 0 {
                try await Task.sleep(nanoseconds: delay)
            }
            if let error = errors[page] {
                throw error
            }
            if let error = error {
                throw error
            }
            return self.pages[page]!
        }

        func fetchMovies(page: Int, genre: Movie_Explorer.Genres) async throws -> Movie_Explorer.Page {
            if let error = error {
                throw error
            }
            return self.pages[page]!
        }
    }

    enum MockError: Error {
        case error
    }

    @Test func testRequestPage() async {
        let repository = MockMoviesRepository()
        let viewModel = MoviesViewModel(repository: repository)
        repository.pages.updateValue(Page(page: 1, results: [firstMovie], totalPages: 0), forKey: 1)
        
        viewModel.fetchMovies()
        
        await viewModel.waitForStateContent()
        
        guard case let .content(movies, error) = viewModel.state else {
            Issue.record("Expected content without error")
            return
        }
        
        #expect(movies == [firstMovie])
        #expect(error == nil)
    }
    
    @Test func testRequestNextPage() async {
        let repository = MockMoviesRepository()
        let viewModel = MoviesViewModel(repository: repository)
        repository.pages.updateValue(Page(page: 1, results: [firstMovie], totalPages: 2), forKey: 1)
        repository.pages.updateValue(Page(page: 2, results: [secondMovie], totalPages: 2), forKey: 2)
        
        viewModel.fetchMovies()
        await viewModel.waitForStateContent()
        
        viewModel.fetchMoreMovies()
        await Task.yield()
        
        guard case let .content(movies, error) = viewModel.state else {
            Issue.record("Expected content without error")
            return
        }
        
        #expect(movies == [firstMovie, secondMovie])
        #expect(error == nil)
    }
    
    @Test func testRefreshPage() async {
        let repository = MockMoviesRepository()
        let viewModel = MoviesViewModel(repository: repository)
        repository.pages.updateValue(Page(page: 1, results: [firstMovie], totalPages: 0), forKey: 1)
        
        viewModel.refreshMovies()
        
        await viewModel.waitForStateContent()
        
        guard case let .content(movies, error) = viewModel.state else {
            Issue.record("Expected content without error")
            return
        }
        
        #expect(movies == [firstMovie])
        #expect(error == nil)
    }
    
    @Test func testFailRequestPage() async {
        let repository = MockMoviesRepository()
        let viewModel = MoviesViewModel(repository: repository)
        repository.error = MockError.error

        viewModel.fetchMovies()

        await viewModel.waitForStateContent()

        guard case let .content(movies, error) = viewModel.state else {
            Issue.record("Expected content with error")
            return
        }

        #expect(movies.isEmpty)
        #expect(error != nil)
    }

    @Test func testFetchMoreMoviesFailurePreservesExistingMovies() async {
        let repository = MockMoviesRepository()
        let viewModel = MoviesViewModel(repository: repository)
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 2)
        repository.errors[2] = MockError.error

        viewModel.fetchMovies()
        await viewModel.waitForStateContent()

        viewModel.fetchMoreMovies()
        await waitUntil {
            if case .content(_, let error) = viewModel.state { return error != nil }
            return false
        }

        guard case let .content(movies, error) = viewModel.state else {
            Issue.record("Expected content state with a non-blocking pagination error")
            return
        }
        #expect(movies == [firstMovie])
        #expect(error != nil)
    }

    @Test func testReloadLastPageRetriesTheFailedPageAndKeepsExistingMovies() async {
        let repository = MockMoviesRepository()
        let viewModel = MoviesViewModel(repository: repository)
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 2)
        repository.errors[2] = MockError.error

        viewModel.fetchMovies()
        await viewModel.waitForStateContent()

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

        guard case let .content(movies, error) = viewModel.state else {
            Issue.record("Expected content state after successful reload")
            return
        }
        #expect(movies == [firstMovie, secondMovie])
        #expect(error == nil)
        #expect(repository.requestedPages == [1, 2, 2])
    }

    @Test func testConcurrentFetchMoreMoviesDoesNotSkipOrDuplicatePages() async {
        let repository = MockMoviesRepository()
        let viewModel = MoviesViewModel(repository: repository)
        let thirdMovie = Movie(id: 3, title: "Cars", overview: "", posterPath: nil, releaseDate: Date())
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 3)
        repository.pages[2] = Page(page: 2, results: [secondMovie], totalPages: 3)
        repository.pages[3] = Page(page: 3, results: [thirdMovie], totalPages: 3)
        repository.delayNanosecondsByPage[2] = 100_000_000

        viewModel.fetchMovies()
        await viewModel.waitForStateContent()

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
}

private extension MoviesViewModel {

    func waitForStateContent() async {
        while true {
            if case .content = state {
                return
            }
            await Task.yield()
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
