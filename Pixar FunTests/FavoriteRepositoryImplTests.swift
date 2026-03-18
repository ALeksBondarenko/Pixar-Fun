//
//  FavoriteRepositoryImplTests.swift
//  Pixar FunTests
//
//  Created by Александр Бондаренко on 07.03.2026.
//

import Testing
@testable import Pixar_Fun
import Foundation

@MainActor
struct FavoriteRepositoryImplTests {
    
    final class MockFavoriteService: FavoriteServiceProtocol {
        
        var error: Error?
        
        var result: Page?
        var page: Int?
        
        func fetchFavoriteMovies(page: Int) async throws -> Page {
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
    func testFetchFavoriteMoviesDelegatesToService() async {
        let service = MockFavoriteService()
        let movie = Movie(id: 1, title: "Toy Story", overview: "", posterPath: nil, releaseDate: nil)
        let expectedPage = Page(page: 1, results: [movie], totalPages: 1)
        service.result = expectedPage
        
        let repository = FavoriteRepositoryImpl(service: service)
        
        do {
            let result = try await repository.fetchFavoriteMovies(page: 2)
            
            #expect(result == expectedPage)
            #expect(service.page == 2)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
    
    @Test
    func testFetchFavoriteMoviesPropagatesServiceError() async {
        let service = MockFavoriteService()
        service.error = MockError.failed
        let repository = FavoriteRepositoryImpl(service: service)
        
        do {
            _ = try await repository.fetchFavoriteMovies(page: 1)
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

