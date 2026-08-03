//
//  SearchService.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 03.08.2026.
//

import Foundation

protocol SearchServiceProtocol {

    func searchMovies(query: String, page: Int) async throws -> Page

    func searchPersons(query: String, page: Int) async throws -> PersonsPage

    func searchKeywords(query: String, page: Int) async throws -> KeywordsPage
}

class SearchService: SearchServiceProtocol {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func searchMovies(query: String, page: Int) async throws -> Page {
        try await networkClient.request(
            .get("https://api.themoviedb.org/3/search/movie"),
            queryParams: [
                Param(name: "query", value: query),
                Param(name: "page", value: page),
                Param(name: "include_adult", value: "false"),
                Param(name: "language", value: iso3166LanguageCode(Locale.current)),
            ]
        )
    }

    func searchPersons(query: String, page: Int) async throws -> PersonsPage {
        try await networkClient.request(
            .get("https://api.themoviedb.org/3/search/person"),
            queryParams: [
                Param(name: "query", value: query),
                Param(name: "page", value: page),
                Param(name: "include_adult", value: "false"),
                Param(name: "language", value: iso3166LanguageCode(Locale.current)),
            ]
        )
    }

    func searchKeywords(query: String, page: Int) async throws -> KeywordsPage {
        try await networkClient.request(
            .get("https://api.themoviedb.org/3/search/keyword"),
            queryParams: [
                Param(name: "query", value: query),
                Param(name: "page", value: page),
            ]
        )
    }
}
