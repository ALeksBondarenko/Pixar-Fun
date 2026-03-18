//
//  MoviesViewModelTests.swift
//  Pixar FunTests
//
//  Created by Александр Бондаренко on 25.01.2026.
//

import Testing
@testable import Pixar_Fun
import Foundation

@MainActor
struct MoviesViewModelTests {
    let firstMovie = Movie(id: 1, title: "Toy Story", overview: "", posterPath: "/posterPath.jpg", releaseDate: Date())
    let secondMovie = Movie(id: 2, title: "Hoppers", overview: "", posterPath: "/posterPath.jpg", releaseDate: Date())
                                
    class MockMoviesRepository: MoviesRepository {
        
        var pages = [Int:Page]()
        var error: Error?
        
        func fetchMovies(page: Int) async throws -> Page {
            if let error = error {
                throw error
            }
            return self.pages[page]!
        }
        
        func fetchMovies(page: Int, genre: Pixar_Fun.Genres) async throws -> Pixar_Fun.Page {
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
