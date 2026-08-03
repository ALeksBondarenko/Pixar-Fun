//
//  SearchRepositoryImplTests.swift
//  Movie ExplorerTests
//
//  Created by Александр Бондаренко on 03.08.2026.
//

import Testing
@testable import Movie_Explorer
import Foundation

@MainActor
struct SearchRepositoryImplTests {

    final class MockSearchService: SearchServiceProtocol {
        var receivedQuery: String?
        var receivedPage: Int?

        var moviesResult: Page?
        var personsResult: PersonsPage?
        var keywordsResult: KeywordsPage?
        var error: Error?

        func searchMovies(query: String, page: Int) async throws -> Page {
            receivedQuery = query
            receivedPage = page
            if let error { throw error }
            guard let moviesResult else {
                Issue.record("moviesResult is not set")
                throw MockError.resultNotSet
            }
            return moviesResult
        }

        func searchPersons(query: String, page: Int) async throws -> PersonsPage {
            receivedQuery = query
            receivedPage = page
            if let error { throw error }
            guard let personsResult else {
                Issue.record("personsResult is not set")
                throw MockError.resultNotSet
            }
            return personsResult
        }

        func searchKeywords(query: String, page: Int) async throws -> KeywordsPage {
            receivedQuery = query
            receivedPage = page
            if let error { throw error }
            guard let keywordsResult else {
                Issue.record("keywordsResult is not set")
                throw MockError.resultNotSet
            }
            return keywordsResult
        }
    }

    enum MockError: Error {
        case resultNotSet
        case failed
    }

    @Test
    func testSearchMoviesDelegatesToService() async throws {
        let service = MockSearchService()
        let movie = Movie(id: 1, title: "Toy Story", overview: "", posterPath: nil, releaseDate: nil)
        service.moviesResult = Page(page: 1, results: [movie], totalPages: 1)

        let repository = SearchRepositoryImpl(service: service)
        let result = try await repository.searchMovies(query: "toy", page: 1)

        #expect(result == service.moviesResult)
        #expect(service.receivedQuery == "toy")
        #expect(service.receivedPage == 1)
    }

    @Test
    func testSearchPersonsDelegatesToService() async throws {
        let service = MockSearchService()
        let cast = Cast(id: 1, character: nil, name: "Tom Hanks", profilePath: nil)
        service.personsResult = PersonsPage(page: 1, results: [cast], totalPages: 1)

        let repository = SearchRepositoryImpl(service: service)
        let result = try await repository.searchPersons(query: "tom", page: 2)

        #expect(result == service.personsResult)
        #expect(service.receivedQuery == "tom")
        #expect(service.receivedPage == 2)
    }

    @Test
    func testSearchKeywordsDelegatesToService() async throws {
        let service = MockSearchService()
        let keyword = Keyword(id: 1, name: "space")
        service.keywordsResult = KeywordsPage(page: 1, results: [keyword], totalPages: 1)

        let repository = SearchRepositoryImpl(service: service)
        let result = try await repository.searchKeywords(query: "spa", page: 1)

        #expect(result == service.keywordsResult)
        #expect(service.receivedQuery == "spa")
    }

    @Test
    func testRepositoryPropagatesServiceError() async {
        let service = MockSearchService()
        service.error = MockError.failed
        let repository = SearchRepositoryImpl(service: service)

        do {
            _ = try await repository.searchMovies(query: "toy", page: 1)
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
