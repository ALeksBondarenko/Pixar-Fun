//
//  PersonRepositoryImplTests.swift
//  Pixar FunTests
//
//  Created by Александр Бондаренко on 07.03.2026.
//

import Testing
@testable import Pixar_Fun
import Foundation

@MainActor
struct PersonRepositoryImplTests {
    
    final class MockPersonService: PersonServiceProtocol {
        
        var error: Error?
        
        var personResult: Person?
        var personId: Int?
        
        var imagesResult: PersonImages?
        var imagesPersonId: Int?
        
        var pageResult: Page?
        var moviesPersonId: Int?
        var moviesPage: Int?
        
        func getPerson(id: Int) async throws -> Person {
            if let error = error {
                throw error
            }
            personId = id
            guard let result = personResult else {
                Issue.record("personResult is not set")
                throw MockError.resultNotSet
            }
            return result
        }
        
        func getPhotos(personId: Int) async throws -> PersonImages {
            if let error = error {
                throw error
            }
            imagesPersonId = personId
            guard let result = imagesResult else {
                Issue.record("imagesResult is not set")
                throw MockError.resultNotSet
            }
            return result
        }
        
        func getMoviesWithPerson(personId: Int, page: Int) async throws -> Page {
            if let error = error {
                throw error
            }
            moviesPersonId = personId
            moviesPage = page
            guard let result = pageResult else {
                Issue.record("pageResult is not set")
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
    func testGetPersonDelegatesToService() async {
        let service = MockPersonService()
        let person = Person(
            id: 1,
            name: "Tom Hanks",
            profilePath: "profile",
            biography: "bio",
            birthday: nil,
            deathday: nil,
            placeOfBirth: "place"
        )
        service.personResult = person
        
        let repository = PersonRepositoryImpl(service: service)
        
        do {
            let result = try await repository.getPerson(personId: 1)
            
            #expect(result == person)
            #expect(service.personId == 1)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
    
    @Test
    func testGetPersonImagesDelegatesToService() async {
        let service = MockPersonService()
        let images = PersonImages(profiles: [
            PersonImage(filePath: "path1"),
            PersonImage(filePath: "path2")
        ])
        service.imagesResult = images
        
        let repository = PersonRepositoryImpl(service: service)
        
        do {
            let result = try await repository.getPersonImages(personId: 2)
            
            #expect(result == images.profiles)
            #expect(service.imagesPersonId == 2)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
    
    @Test
    func testGetMoviesWithPersonDelegatesToService() async {
        let service = MockPersonService()
        let movie = Movie(id: 1, title: "Toy Story", overview: "", posterPath: nil, releaseDate: nil)
        let page = Page(page: 1, results: [movie], totalPages: 1)
        service.pageResult = page
        
        let repository = PersonRepositoryImpl(service: service)
        
        do {
            let result = try await repository.getMoviesWithPerson(personId: 3, page: 4)
            
            #expect(result == page)
            #expect(service.moviesPersonId == 3)
            #expect(service.moviesPage == 4)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
    
    @Test
    func testRepositoryPropagatesServiceError() async {
        let service = MockPersonService()
        service.error = MockError.failed
        let repository = PersonRepositoryImpl(service: service)
        
        do {
            _ = try await repository.getPerson(personId: 1)
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

