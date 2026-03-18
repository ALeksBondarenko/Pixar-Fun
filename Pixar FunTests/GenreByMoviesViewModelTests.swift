//
//  GenreByMoviesViewModelTests.swift
//  Pixar FunTests
//
//  Created by Александр Бондаренко on 07.03.2026.
//

import Testing
@testable import Pixar_Fun
import Foundation

@MainActor
struct GenreByMoviesViewModelTests {
    
    struct MockMoviesRepository: MoviesRepository {
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

