//
//  PersonRepoditory.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 27.12.2025.
//

import Foundation

class PersonRepositoryImpl : PersonRepository {
    
    private let service: PersonServiceProtocol
    
    init(service: PersonServiceProtocol) {
        self.service = service
    }
    
    func getPerson(personId: Int) async throws -> Person {
        try await service.getPerson(id: personId)
    }
    
    func getPersonImages(personId: Int) async throws -> [PersonImage] {
        try await service.getPhotos(personId: personId).profiles
    }
    
    func getMoviesWithPerson(personId: Int, page: Int) async throws -> Page {
        try await service.getMoviesWithPerson(personId: personId, page: page)
    }
}
