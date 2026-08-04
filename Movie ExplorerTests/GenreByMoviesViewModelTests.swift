//
//  GenreByMoviesViewModelTests.swift
//  Movie ExplorerTests
//
//  Created by Александр Бондаренко on 07.03.2026.
//

import Testing
@testable import Movie_Explorer
import Foundation

@MainActor
struct GenreByMoviesViewModelTests {
    
    final class MockMoviesRepository: MoviesRepository {
        var pages: [Int: Page] = [:]
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
            guard let page = pages[page] else {
                Issue.record("Page \(page) not found")
                throw MockError.missingPage
            }
            return page
        }

        func fetchMovies(page: Int, genre: Genres) async throws -> Page {
            try await fetchMovies(page: page)
        }
    }
    
    enum MockError: Error {
        case missingPage
        case failed
    }
    
    let genre = Genres(id: 1, name: "adventure")
    let firstMovie = Movie(id: 1, title: "Toy Story", overview: "", posterPath: nil, releaseDate: Date())
    let secondMovie = Movie(id: 2, title: "Finding Nemo", overview: "", posterPath: nil, releaseDate: Date())
    
    @Test
    func testInitialTitleIsCapitalizedGenreName() {
        let repository = MockMoviesRepository()
        let viewModel = GenreByMoviesViewModel(repository: repository, genre: genre)
        
        #expect(viewModel.title == "Adventure")
    }
    
    @Test
    func testFetchMoviesSuccess() async {
        var repository = MockMoviesRepository()
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 1)
        
        let viewModel = GenreByMoviesViewModel(repository: repository, genre: genre)
        
        viewModel.fetchMovies()
        
        await viewModel.waitForStateContent()
        
        guard case let .content(movies, error) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }
        
        #expect(movies == [firstMovie])
        #expect(error == nil)
    }
    
    @Test
    func testFetchMoreMoviesAppendsResults() async {
        var repository = MockMoviesRepository()
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 2)
        repository.pages[2] = Page(page: 2, results: [secondMovie], totalPages: 2)
        
        let viewModel = GenreByMoviesViewModel(repository: repository, genre: genre)
        
        viewModel.fetchMovies()
        await viewModel.waitForStateContent()
        
        viewModel.fetchMoreMovies()
        await Task.yield()
        
        guard case let .content(movies, error) = viewModel.state else {
            Issue.record("Expected content state after loading next page")
            return
        }
        
        #expect(movies == [firstMovie, secondMovie])
        #expect(error == nil)
    }
    
    @Test
    func testRefreshMoviesResetsAndLoadsFirstPage() async {
        var repository = MockMoviesRepository()
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 1)
        
        let viewModel = GenreByMoviesViewModel(repository: repository, genre: genre)
        
        viewModel.refreshMovies()
        
        await viewModel.waitForStateContent()
        
        guard case let .content(movies, error) = viewModel.state else {
            Issue.record("Expected content state after refresh")
            return
        }
        
        #expect(movies == [firstMovie])
        #expect(error == nil)
    }
    
    @Test
    func testFetchMoviesFailureSetsError() async {
        var repository = MockMoviesRepository()
        repository.error = MockError.failed
        
        let viewModel = GenreByMoviesViewModel(repository: repository, genre: genre)
        
        viewModel.fetchMovies()
        
        await viewModel.waitForStateContent()
        
        guard case let .content(movies, error) = viewModel.state else {
            Issue.record("Expected content state with error")
            return
        }
        
        #expect(movies.isEmpty)
        #expect(error != nil)
    }
    
    @Test
    func testClearErrorRemovesErrorPreservingMovies() async {
        var repository = MockMoviesRepository()
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 1)
        
        let viewModel = GenreByMoviesViewModel(repository: repository, genre: genre)
        
        viewModel.fetchMovies()
        
        await viewModel.waitForStateContent()
        
        guard case let .content(movies, _) = viewModel.state else {
            Issue.record("Expected content state before clearing error")
            return
        }
        
        #expect(movies == [firstMovie])
        
        viewModel.clearError()

        guard case let .content(movies, error) = viewModel.state else {
            Issue.record("Expected content state after clearing error")
            return
        }

        #expect(movies == [firstMovie])
        #expect(error == nil)
    }

    @Test
    func testReloadLastPageRetriesTheFailedPageAndKeepsExistingMovies() async {
        let repository = MockMoviesRepository()
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 2)
        repository.errors[2] = MockError.failed

        let viewModel = GenreByMoviesViewModel(repository: repository, genre: genre)

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

    @Test
    func testConcurrentFetchMoreMoviesDoesNotSkipOrDuplicatePages() async {
        let repository = MockMoviesRepository()
        let thirdMovie = Movie(id: 3, title: "Cars", overview: "", posterPath: nil, releaseDate: Date())
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 3)
        repository.pages[2] = Page(page: 2, results: [secondMovie], totalPages: 3)
        repository.pages[3] = Page(page: 3, results: [thirdMovie], totalPages: 3)
        repository.delayNanosecondsByPage[2] = 100_000_000

        let viewModel = GenreByMoviesViewModel(repository: repository, genre: genre)

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

private extension GenreByMoviesViewModel {

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

