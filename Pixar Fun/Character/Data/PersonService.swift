//
//  PersonApi.swift
//  Pixar Fan
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
            httpMethod: .GET,
            stringUrl: "https://api.themoviedb.org/3/person/\(id)",
            queryParams: ["language":iso3166LanguageCode(Locale.current)]
        )
    }
    
    func getPhotos(personId: Int) async throws -> PersonImages {
        try await networkClient.request(
            httpMethod: .GET,
            stringUrl: "https://api.themoviedb.org/3/person/\(personId)/images"
        )
    }
    
    func getMoviesWithPerson(personId: Int, page: Int) async throws -> Page {
        try await networkClient.request(
            httpMethod: .GET,
            stringUrl: "https://api.themoviedb.org/3/discover/movie",
            queryParams: [
                "include_adult":"false",
                "language":iso3166LanguageCode(Locale.current),
                "page":"\(page)",
                "sort_by":"primary_release_date.desc",
                "with_companies":"3",
                "with_cast":"\(personId)",
                "with_genres":"16",
            ]
        )
    }
}
