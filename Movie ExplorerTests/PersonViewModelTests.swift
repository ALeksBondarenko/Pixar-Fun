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

    final class MockPersonRepository: PersonRepository {
        var person: Person?
        var errorPerson: Error?

        var images: [PersonImage] = []
        var errorImages: Error?

        var pages: [Int: Page] = [:]
        var errors: [Int: Error] = [:]
        var delayNanosecondsByPage: [Int: UInt64] = [:]
        private(set) var callCount = 0
        private(set) var requestedPages: [Int] = []

        func getPerson(personId: Int) async throws -> Person {
            if let error = errorPerson {
                throw error
            }
            guard let person else {
                Issue.record("person is not set")
                throw MockError.error
            }
            return person
        }

        func getPersonImages(personId: Int) async throws -> [PersonImage] {
            if let error = errorImages {
                throw error
            }
            return images
        }

        func getMoviesWithPerson(personId: Int, page: Int) async throws -> Page {
            callCount += 1
            requestedPages.append(page)
            if let delay = delayNanosecondsByPage[page], delay > 0 {
                try await Task.sleep(nanoseconds: delay)
            }
            if let error = errors[page] {
                throw error
            }
            guard let result = pages[page] else {
                Issue.record("Page \(page) not found")
                throw MockError.error
            }
            return result
        }
    }

    enum MockError: Error {
        case error
    }

    let firstMovie = Movie(id: 1, title: "Toy Story", overview: "", posterPath: nil, releaseDate: nil)
    let secondMovie = Movie(id: 2, title: "Finding Nemo", overview: "", posterPath: nil, releaseDate: nil)
    let thirdMovie = Movie(id: 3, title: "Cars", overview: "", posterPath: nil, releaseDate: nil)
    let person1 = Person(id: 1, name: "Tom Hanks", profilePath: "profilePath", biography: "biography", birthday: nil, deathday: nil, placeOfBirth: "placeOfBirth")

    @Test
    func testSuccessfulInitialLoad() async {
        let repository = MockPersonRepository()
        let images = [PersonImage(filePath: "filePath")]
        repository.person = person1
        repository.images = images
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 1)

        let viewModel = PersonViewModel(repository: repository, cast: cast)

        viewModel.loadInitMoviePage()

        await waitForContentOrError(viewModel: viewModel)

        guard case let .content(person, personImages, movies, error) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(person == person1)
        #expect(personImages == images)
        #expect(movies == [firstMovie])
        #expect(error == nil)
    }

    @Test
    func testInitialLoadFailureSetsErrorState() async {
        let repository = MockPersonRepository()
        repository.errorPerson = MockError.error
        // getPerson is what's expected to fail, but loadInitMoviePage() fetches
        // person/photos/movies concurrently via async let, so the movies page is
        // still requested — configure it so the mock doesn't flag it as missing.
        repository.pages[1] = Page(page: 1, results: [], totalPages: 1)

        let viewModel = PersonViewModel(repository: repository, cast: cast)

        viewModel.loadInitMoviePage()

        await waitForContentOrError(viewModel: viewModel)

        if case .error = viewModel.state {
            // ok
        } else {
            Issue.record("Expected error state when the initial load fails")
        }
    }

    @Test
    func testLoadNextMoviePageAppendsResults() async {
        let repository = MockPersonRepository()
        repository.person = person1
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 2)
        repository.pages[2] = Page(page: 2, results: [secondMovie], totalPages: 2)

        let viewModel = PersonViewModel(repository: repository, cast: cast)
        viewModel.loadInitMoviePage()
        await waitForContentOrError(viewModel: viewModel)

        viewModel.loadNextMoviePage()
        await waitUntil {
            if case .content(_, _, let movies, _) = viewModel.state { return movies.count == 2 }
            return false
        }

        guard case let .content(_, _, movies, error) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(movies == [firstMovie, secondMovie])
        #expect(error == nil)
    }

    @Test
    func testLoadNextMoviePageDoesNothingAfterLastPage() async {
        let repository = MockPersonRepository()
        repository.person = person1
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 1)

        let viewModel = PersonViewModel(repository: repository, cast: cast)
        viewModel.loadInitMoviePage()
        await waitForContentOrError(viewModel: viewModel)

        let callsBefore = repository.callCount
        viewModel.loadNextMoviePage()
        await Task.yield()

        #expect(repository.callCount == callsBefore)
    }

    @Test
    func testLoadNextMoviePageFailurePreservesExistingMovies() async {
        let repository = MockPersonRepository()
        repository.person = person1
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 2)
        repository.errors[2] = MockError.error

        let viewModel = PersonViewModel(repository: repository, cast: cast)
        viewModel.loadInitMoviePage()
        await waitForContentOrError(viewModel: viewModel)

        viewModel.loadNextMoviePage()
        await waitUntil {
            if case .content(_, _, _, let error) = viewModel.state { return error != nil }
            return false
        }

        guard case let .content(_, _, movies, error) = viewModel.state else {
            Issue.record("Expected content state with a non-blocking pagination error")
            return
        }
        #expect(movies == [firstMovie])
        #expect(error != nil)
    }

    @Test
    func testReloadLastPageRetriesTheFailedPageAndKeepsExistingMovies() async {
        let repository = MockPersonRepository()
        repository.person = person1
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 2)
        repository.errors[2] = MockError.error

        let viewModel = PersonViewModel(repository: repository, cast: cast)
        viewModel.loadInitMoviePage()
        await waitForContentOrError(viewModel: viewModel)

        viewModel.loadNextMoviePage()
        await waitUntil {
            if case .content(_, _, _, let error) = viewModel.state { return error != nil }
            return false
        }

        repository.errors[2] = nil
        repository.pages[2] = Page(page: 2, results: [secondMovie], totalPages: 2)

        viewModel.reloadLastPage()
        await waitUntil {
            if case .content(_, _, let movies, _) = viewModel.state { return movies.count == 2 }
            return false
        }

        guard case let .content(_, _, movies, error) = viewModel.state else {
            Issue.record("Expected content state after successful reload")
            return
        }
        #expect(movies == [firstMovie, secondMovie])
        #expect(error == nil)
        #expect(repository.requestedPages == [1, 2, 2])
    }

    @Test
    func testClearErrorKeepsMoviesAndRemovesError() async {
        let repository = MockPersonRepository()
        repository.person = person1
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 2)
        repository.errors[2] = MockError.error

        let viewModel = PersonViewModel(repository: repository, cast: cast)
        viewModel.loadInitMoviePage()
        await waitForContentOrError(viewModel: viewModel)

        viewModel.loadNextMoviePage()
        await waitUntil {
            if case .content(_, _, _, let error) = viewModel.state { return error != nil }
            return false
        }

        viewModel.clearError()

        guard case let .content(_, _, movies, error) = viewModel.state else {
            Issue.record("Expected content state after clearing error")
            return
        }
        #expect(movies == [firstMovie])
        #expect(error == nil)
    }

    @Test
    func testConcurrentLoadNextMoviePageDoesNotSkipOrDuplicatePages() async {
        let repository = MockPersonRepository()
        repository.person = person1
        repository.pages[1] = Page(page: 1, results: [firstMovie], totalPages: 3)
        repository.pages[2] = Page(page: 2, results: [secondMovie], totalPages: 3)
        repository.pages[3] = Page(page: 3, results: [thirdMovie], totalPages: 3)
        repository.delayNanosecondsByPage[2] = 100_000_000

        let viewModel = PersonViewModel(repository: repository, cast: cast)
        viewModel.loadInitMoviePage()
        await waitForContentOrError(viewModel: viewModel)

        // Simulates duplicate onAppear firing for the last cell before the first page-2
        // request has resolved.
        viewModel.loadNextMoviePage()
        viewModel.loadNextMoviePage()

        await waitUntil(timeout: 3) {
            if case .content(_, _, let movies, _) = viewModel.state { return movies.count == 2 }
            return false
        }

        guard case let .content(_, _, movies, error) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(movies == [firstMovie, secondMovie])
        #expect(error == nil)

        // Page 2 must not have been skipped in favor of page 3.
        viewModel.loadNextMoviePage()
        await waitUntil(timeout: 3) {
            if case .content(_, _, let movies, _) = viewModel.state { return movies.count == 3 }
            return false
        }
        guard case let .content(_, _, finalMovies, _) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(finalMovies == [firstMovie, secondMovie, thirdMovie])
    }
}

@MainActor
private func waitForContentOrError(viewModel: PersonViewModel) async {
    while true {
        switch viewModel.state {
        case .loading:
            await Task.yield()
        case .content, .error:
            return
        }
    }
}

@MainActor
private func waitUntil(timeout: TimeInterval = 3, _ condition: () -> Bool) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() && Date() < deadline {
        await Task.yield()
    }
}
