//
//  SearchViewModelTests.swift
//  Pixar FunTests
//
//  Created by Александр Бондаренко on 07.03.2026.
//

import Testing
@testable import Pixar_Fun
import Foundation

@MainActor
struct SearchViewModelTests {
    
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
    
    @Test
    func testSearchWithShortQueryResetsToIdle() async {
        let repository = MockMoviesRepository()
        let viewModel = SearchViewModel(repository: repository)
        
        viewModel.search("to")
        
        if case .idle = viewModel.state {
            // ok
        } else {
            Issue.record("Expected idle state for short query")
        }
    }
    
    @Test
    func testSuccessfulSearchAfterLoadingAllMovies() async {
        let firstMovie = Movie(id: 1, title: "Toy Story", overview: "", posterPath: nil, releaseDate: Date())
        let secondMovie = Movie(id: 2, title: "Finding Nemo", overview: "", posterPath: nil, releaseDate: Date())
        
        var repository = MockMoviesRepository()
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 2)
        repository.pages[2] = Page(page: 2, results: [secondMovie], totalPages: 2)
        
        let viewModel = SearchViewModel(repository: repository)
        
        viewModel.loadAllMovies()
        
        await waitForBackgroundWork()
        
        viewModel.search("toy")
        
        guard case let .found(movies) = viewModel.state else {
            Issue.record("Expected found state")
            return
        }
        
        #expect(movies == [firstMovie])
    }
    
    @Test
    func testSearchFoundAndEmptyStates() async {
        let toyStory = Movie(id: 1, title: "Toy Story", overview: "", posterPath: nil, releaseDate: Date())
        let nemo = Movie(id: 2, title: "Finding Nemo", overview: "", posterPath: nil, releaseDate: Date())
        
        var repository = MockMoviesRepository()
        repository.pages[1] = Page(page: 1, results: [toyStory, nemo], totalPages: 1)
        
        let viewModel = SearchViewModel(repository: repository)
        
        viewModel.loadAllMovies()
        
        await waitForBackgroundWork()
        
        viewModel.search("nem")
        
        guard case let .found(foundMovies) = viewModel.state else {
            Issue.record("Expected found state")
            return
        }
        
        #expect(foundMovies == [nemo])
        
        viewModel.search("zzz")
        
        if case .empty = viewModel.state {
            // ok
        } else {
            Issue.record("Expected empty state when no movies found")
        }
    }
    
    @Test
    func testLoadAllMoviesErrorChangesStateToError() async {
        var repository = MockMoviesRepository()
        repository.error = MockError.failed
        
        let viewModel = SearchViewModel(repository: repository)
        
        viewModel.loadAllMovies()
        
        await waitForStateError(viewModel: viewModel)
        
        if case .error = viewModel.state {
            // ok
        } else {
            Issue.record("Expected error state after failing to load all movies")
        }
    }
    
    @Test
    func testClearErrorSetsIdleState() async {
        var repository = MockMoviesRepository()
        repository.error = MockError.failed
        
        let viewModel = SearchViewModel(repository: repository)
        
        viewModel.loadAllMovies()
        
        await waitForStateError(viewModel: viewModel)
        
        viewModel.clearError()
        
        if case .idle = viewModel.state {
            // ok
        } else {
            Issue.record("Expected idle state after clearing error")
        }
    }
}

@MainActor
private func waitForBackgroundWork() async {
    // Достаточно подождать несколько тактов, чтобы фоновые Task завершились
    for _ in 0..<10 {
        await Task.yield()
    }
}

@MainActor
private func waitForStateError(viewModel: SearchViewModel) async {
    while true {
        if case .error = viewModel.state {
            return
        }
        await Task.yield()
    }
}

