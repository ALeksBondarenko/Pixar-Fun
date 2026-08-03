//
//  SearchRepositoryImpl.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 03.08.2026.
//

import Foundation

class SearchRepositoryImpl: SearchRepository {

    private let service: SearchServiceProtocol

    init(service: SearchServiceProtocol) {
        self.service = service
    }

    func searchMovies(query: String, page: Int) async throws -> Page {
        try await service.searchMovies(query: query, page: page)
    }

    func searchPersons(query: String, page: Int) async throws -> PersonsPage {
        try await service.searchPersons(query: query, page: page)
    }

    func searchKeywords(query: String, page: Int) async throws -> KeywordsPage {
        try await service.searchKeywords(query: query, page: page)
    }
}
