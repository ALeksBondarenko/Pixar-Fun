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
        var page: Int?
        
        func fetchWatchListMovies(page: Int) async throws -> Page {
            if let error = error {
                throw error
            }
            self.page = page
            
            guard let result = result else {
                Issue.record("result is not set")
                throw MockError.resultNotSet
            }
            return result
        }
    }
    
    enum MockError: Error {
        case resultNotSet
        case failed
    }
    
    @Test
    func testFetchMoviesDelegatesToService() async {
        let service = MockWatchListService()
        let movie = Movie(id: 1, title: "Toy Story", overview: "", posterPath: nil, releaseDate: nil)
        let expectedPage = Page(page: 1, results: [movie], totalPages: 2)
        service.result = expectedPage
        
        let repository = WatchListRepositoryImpl(service: service)
        
        do {
            let result = try await repository.fetchMovies(page: 1)
            
            #expect(result == expectedPage)
            #expect(service.page == 1)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
    
    @Test
    func testFetchMoviesPropagatesServiceError() async {
        let service = MockWatchListService()
        service.error = MockError.failed
        let repository = WatchListRepositoryImpl(service: service)
        
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
}

