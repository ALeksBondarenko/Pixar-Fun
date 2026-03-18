//
//  MoviesRepositoryImplTests.swift
//  Pixar FunTests
//
//  Created by Александр Бондаренко on 07.03.2026.
//

import Testing
@testable import Pixar_Fun
import Foundation

@MainActor
struct MoviesRepositoryImplTests {
    
    final class MockMoviesService: MoviesServiceProtocol {
        var receivedPage: Int?
        var receivedGenre: Genres?
        var result: Page?
        var error: Error?
        
        func fetchPixarMovies(page: Int, genre: Genres?) async throws -> Page {
            receivedPage = page
            receivedGenre = genre
            
            if let error = error {
                throw error
            }
            
            guard let result = result else {
                Issue.record("Result is not set")
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
    func testFetchMoviesWithoutGenreDelegatesToService() async {
        let service = MockMoviesService()
        let movie = Movie(id: 1, title: "Toy Story", overview: "", posterPath: nil, releaseDate: nil)
        let expectedPage = Page(page: 1, results: [movie], totalPages: 1)
        service.result = expectedPage
        
        let repository = MoviesRepositoryImpl(service: service)
        
        do {
            let page = try await repository.fetchMovies(page: 1)
            
            #expect(page == expectedPage)
            #expect(service.receivedPage == 1)
            #expect(service.receivedGenre == nil)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
    
    @Test
    func testFetchMoviesWithGenreDelegatesToService() async {
        let service = MockMoviesService()
        let genre = Genres(id: 16, name: "Animation")
        let movie = Movie(id: 2, title: "Finding Nemo", overview: "", posterPath: nil, releaseDate: nil)
        let expectedPage = Page(page: 2, results: [movie], totalPages: 3)
        service.result = expectedPage
        
        let repository = MoviesRepositoryImpl(service: service)
        
        do {
            let page = try await repository.fetchMovies(page: 2, genre: genre)
            
            #expect(page == expectedPage)
            #expect(service.receivedPage == 2)
            #expect(service.receivedGenre == genre)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
    
    @Test
    func testFetchMoviesPropagatesServiceError() async {
        let service = MockMoviesService()
        service.error = MockError.failed
        let repository = MoviesRepositoryImpl(service: service)
        
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

