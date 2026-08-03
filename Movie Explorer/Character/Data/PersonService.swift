//
//  PersonApi.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 27.12.2025.
//

import Foundation

protocol PersonServiceProtocol {

    func getPerson(id: Int) async throws -> Person

    func getPhotos(personId: Int) async throws -> PersonImages

    func getMoviesWithPerson(personId: Int, page: Int) async throws -> Page
}

class PersonService: PersonServiceProtocol {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func getPerson(id: Int) async throws -> Person {
        try await networkClient.request(
            .get("https://api.themoviedb.org/3/person/\(id)"),
            queryParams: [Param(name: "language", value: iso3166LanguageCode(Locale.current))]
        )
    }

    func getPhotos(personId: Int) async throws -> PersonImages {
        try await networkClient.request(.get("https://api.themoviedb.org/3/person/\(personId)/images"))
    }

    func getMoviesWithPerson(personId: Int, page: Int) async throws -> Page {
        try await networkClient.request(
            .get("https://api.themoviedb.org/3/discover/movie"),
            queryParams: [
                Param(name: "include_adult", value: "false"),
                Param(name: "language", value: iso3166LanguageCode(Locale.current)),
                Param(name: "page", value: page),
                Param(name: "sort_by", value: "primary_release_date.desc"),
                Param(name: "with_cast", value: personId),
            ]
        )
    }
}
