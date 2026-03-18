//
//  PersonRepository.swift
//  Pixar Fun
//
//  Created by Александр Бондаренко on 25.01.2026.
//

import Foundation

protocol PersonRepository {
    
    func getPerson(personId: Int) async throws -> Person
    
    func getPersonImages(personId: Int) async throws -> [PersonImage]
    
    func getMoviesWithPerson(personId: Int, page: Int) async throws -> Page
}
