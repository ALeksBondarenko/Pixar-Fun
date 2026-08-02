//
//  PersonViewModelTests.swift
//  Movie ExplorerTests
//
//  Created by Александр Бондаренко on 27.01.2026.
//

import Testing
@testable import Movie_Explorer
import Foundation

@MainActor
struct PersonViewModelTests {
    
    let cast = Cast(id: 1, character: nil, name: nil, profilePath: nil)
    
    class MockPersonRepository: PersonRepository {
        var person: Person?
        var errorPerson: Error?
    
        var images: [PersonImage] = []
        var errorImages: Error?
        
        var pages = [Int:Page]()
        var errorPages: Error?
        
        
        func getPerson(personId: Int) async throws -> Person {
            if let error = errorPerson {
                throw error
            }
            return self.person!
        }
        
        func getPersonImages(personId: Int) async throws -> [PersonImage] {
            if let error = errorImages {
                throw error
            }
            return images
        }
        
        func getMoviesWithPerson(personId: Int, page: Int) async throws -> Page {
            if let error = errorPages {
                throw error
            }
            return pages[page]!
        }
    }
    
    enum MockError: Error {
        case error
    }
    
    @Test func testSuccefulLoadData() async {
        let movie = Movie(id: 1, title: "Toy Story", overview: "overview", posterPath: nil, releaseDate: nil)
        let person1 = Person(id: 1, name: "Tom Hanks", profilePath: "profilePath", biography: "biography", birthday: nil, deathday: nil, placeOfBirth: "placeOfBirth")
        let images = [PersonImage(filePath: "filePath")]
        let pages = [1: Page(page: 1, results: [movie], totalPages: 1)]
        let repository = MockPersonRepository()
        repository.person = person1
        repository.images = images
        repository.pages = pages
        
        let viewModel = PersonViewModel(repository: repository, cast: cast)
        
        
        viewModel.load()
        
        await viewModel.waitForStateContent()
        
        guard case let .content(person, personImages, movies) = viewModel.state else {
            Issue.record("Expected content without error")
            return
        }
        
        #expect(person == person1)
        #expect(personImages == images)
        #expect(movies == [movie])
    }
}

private extension PersonViewModel {
    
    func waitForStateContent() async {
        while true {
            if case .content = state {
                return
            }
            await Task.yield()
        }
    }
}
