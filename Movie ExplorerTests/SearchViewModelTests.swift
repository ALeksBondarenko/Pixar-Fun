//
//  SearchViewModelTests.swift
//  Movie ExplorerTests
//
//  Created by Александр Бондаренко on 07.03.2026.
//

import Testing
@testable import Movie_Explorer
import Foundation

@MainActor
struct SearchViewModelTests {

    final class MockSearchRepository: SearchRepository {
        var moviesPages: [String: [Int: Page]] = [:]
        var moviesErrors: [String: [Int: Error]] = [:]
        var moviesDelayByQuery: [String: UInt64] = [:]
        private(set) var moviesCallCount = 0
        private(set) var moviesRequestedPages: [Int] = []

        var personsPages: [String: [Int: PersonsPage]] = [:]
        var personsErrors: [String: [Int: Error]] = [:]
        private(set) var personsCallCount = 0
        private(set) var personsRequestedPages: [Int] = []

        var keywordsPages: [String: [Int: KeywordsPage]] = [:]
        var keywordsErrors: [String: [Int: Error]] = [:]
        private(set) var keywordsCallCount = 0
        private(set) var keywordsRequestedPages: [Int] = []

        func searchMovies(query: String, page: Int) async throws -> Page {
            moviesCallCount += 1
            moviesRequestedPages.append(page)
            if let delay = moviesDelayByQuery[query], delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            if let error = moviesErrors[query]?[page] {
                throw error
            }
            guard let result = moviesPages[query]?[page] else {
                throw MockError.missingPage
            }
            return result
        }

        func searchPersons(query: String, page: Int) async throws -> PersonsPage {
            personsCallCount += 1
            personsRequestedPages.append(page)
            if let error = personsErrors[query]?[page] {
                throw error
            }
            guard let result = personsPages[query]?[page] else {
                throw MockError.missingPage
            }
            return result
        }

        func searchKeywords(query: String, page: Int) async throws -> KeywordsPage {
            keywordsCallCount += 1
            keywordsRequestedPages.append(page)
            if let error = keywordsErrors[query]?[page] {
                throw error
            }
            guard let result = keywordsPages[query]?[page] else {
                throw MockError.missingPage
            }
            return result
        }
    }

    enum MockError: Error {
        case missingPage
        case failed
    }

    @Test
    func testEmptyQueryResetsToIdle() async {
        let repository = MockSearchRepository()
        let viewModel = SearchViewModel(repository: repository)

        viewModel.query = "toy"
        viewModel.query = ""

        if case .idle = viewModel.state {
            // ok
        } else {
            Issue.record("Expected idle state for empty query")
        }
        #expect(repository.moviesCallCount == 0)
    }

    @Test
    func testShortQueryDoesNotTriggerNetwork() async {
        let repository = MockSearchRepository()
        let viewModel = SearchViewModel(repository: repository)

        viewModel.query = "to"

        if case .idle = viewModel.state {
            // ok
        } else {
            Issue.record("Expected idle state for a query shorter than the minimum length")
        }
        #expect(repository.moviesCallCount == 0)
        #expect(repository.personsCallCount == 0)
        #expect(repository.keywordsCallCount == 0)
    }

    @Test
    func testDebounceTriggersAllThreeEndpoints() async {
        let repository = MockSearchRepository()
        repository.moviesPages["toy"] = [1: Page(page: 1, results: [], totalPages: 1)]
        repository.personsPages["toy"] = [1: PersonsPage(page: 1, results: [], totalPages: 1)]
        repository.keywordsPages["toy"] = [1: KeywordsPage(page: 1, results: [], totalPages: 1)]

        let viewModel = SearchViewModel(repository: repository)
        viewModel.query = "toy"

        #expect(repository.moviesCallCount == 0)

        await waitForContent(viewModel)

        #expect(repository.moviesCallCount == 1)
        #expect(repository.personsCallCount == 1)
        #expect(repository.keywordsCallCount == 1)
    }

    @Test
    func testNewQueryCancelsPreviousDebounce() async {
        let repository = MockSearchRepository()
        let freshMovie = Movie(id: 2, title: "Toy Story", overview: "", posterPath: nil, releaseDate: nil)
        repository.moviesPages["toy story"] = [1: Page(page: 1, results: [freshMovie], totalPages: 1)]
        repository.personsPages["toy story"] = [1: PersonsPage(page: 1, results: [], totalPages: 1)]
        repository.keywordsPages["toy story"] = [1: KeywordsPage(page: 1, results: [], totalPages: 1)]

        let viewModel = SearchViewModel(repository: repository)
        viewModel.query = "toy"
        try? await Task.sleep(nanoseconds: 100_000_000)
        viewModel.query = "toy story"

        await waitForContent(viewModel)

        #expect(repository.moviesCallCount == 1)
        guard case let .content(content) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(content.query == "toy story")
        #expect(content.movies.items.map(\.id) == [2])
    }

    @Test
    func testStaleResponseDoesNotOverwriteNewerQuery() async {
        let repository = MockSearchRepository()
        let staleMovie = Movie(id: 1, title: "Toy", overview: "", posterPath: nil, releaseDate: nil)
        let freshMovie = Movie(id: 2, title: "Toy Story", overview: "", posterPath: nil, releaseDate: nil)

        repository.moviesPages["toy"] = [1: Page(page: 1, results: [staleMovie], totalPages: 1)]
        repository.personsPages["toy"] = [1: PersonsPage(page: 1, results: [], totalPages: 1)]
        repository.keywordsPages["toy"] = [1: KeywordsPage(page: 1, results: [], totalPages: 1)]
        repository.moviesDelayByQuery["toy"] = 300_000_000 // slow and ignores cancellation

        repository.moviesPages["toy story"] = [1: Page(page: 1, results: [freshMovie], totalPages: 1)]
        repository.personsPages["toy story"] = [1: PersonsPage(page: 1, results: [], totalPages: 1)]
        repository.keywordsPages["toy story"] = [1: KeywordsPage(page: 1, results: [], totalPages: 1)]

        let viewModel = SearchViewModel(repository: repository)

        viewModel.selectSuggestion(Keyword(id: 1, name: "toy"))
        await Task.yield()
        viewModel.selectSuggestion(Keyword(id: 2, name: "toy story"))

        await waitUntil(timeout: 3) {
            if case .content(let content) = viewModel.state { return content.query == "toy story" }
            return false
        }

        // Give the slow, stale "toy" response a chance to arrive and (incorrectly) overwrite state.
        try? await Task.sleep(nanoseconds: 400_000_000)

        guard case let .content(content) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(content.query == "toy story")
        #expect(content.movies.items.map(\.id) == [2])
    }

    @Test
    func testSuccessfulSearchReturnsMoviesPersonsAndSuggestions() async {
        let repository = MockSearchRepository()
        let movie = Movie(id: 1, title: "Toy Story", overview: "", posterPath: nil, releaseDate: nil)
        let cast = Cast(id: 1, character: nil, name: "Tom Hanks", profilePath: nil)
        let keyword = Keyword(id: 1, name: "toys")
        repository.moviesPages["toy"] = [1: Page(page: 1, results: [movie], totalPages: 1)]
        repository.personsPages["toy"] = [1: PersonsPage(page: 1, results: [cast], totalPages: 1)]
        repository.keywordsPages["toy"] = [1: KeywordsPage(page: 1, results: [keyword], totalPages: 1)]

        let viewModel = SearchViewModel(repository: repository)
        viewModel.query = "toy"

        await waitForContent(viewModel)

        guard case let .content(content) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(content.movies.items == [movie])
        #expect(content.persons.items == [cast])
        #expect(content.suggestions.items == [keyword])
    }

    @Test
    func testPartialErrorPreservesOtherSections() async {
        let repository = MockSearchRepository()
        repository.moviesErrors["toy"] = [1: MockError.failed]
        repository.personsPages["toy"] = [1: PersonsPage(page: 1, results: [Cast(id: 1, character: nil, name: "Tom Hanks", profilePath: nil)], totalPages: 1)]
        repository.keywordsPages["toy"] = [1: KeywordsPage(page: 1, results: [Keyword(id: 1, name: "toys")], totalPages: 1)]

        let viewModel = SearchViewModel(repository: repository)
        viewModel.selectSuggestion(Keyword(id: 99, name: "toy"))

        await waitForContent(viewModel)

        guard case let .content(content) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(content.movies.items.isEmpty)
        #expect(content.movies.initialError != nil)
        #expect(content.persons.items.count == 1)
        #expect(content.suggestions.items.count == 1)
    }

    @Test
    func testAllEndpointsFailingProducesErrorState() async {
        let repository = MockSearchRepository()
        repository.moviesErrors["toy"] = [1: MockError.failed]
        repository.personsErrors["toy"] = [1: MockError.failed]
        repository.keywordsErrors["toy"] = [1: MockError.failed]

        let viewModel = SearchViewModel(repository: repository)
        viewModel.selectSuggestion(Keyword(id: 1, name: "toy"))

        await waitUntil { if case .error = viewModel.state { return true }; return false }

        if case .error = viewModel.state {
            // ok
        } else {
            Issue.record("Expected error state when all endpoints fail")
        }
    }

    @Test
    func testAllEndpointsEmptyProducesEmptyContent() async {
        let repository = MockSearchRepository()
        repository.moviesPages["toy"] = [1: Page(page: 1, results: [], totalPages: 1)]
        repository.personsPages["toy"] = [1: PersonsPage(page: 1, results: [], totalPages: 1)]
        repository.keywordsPages["toy"] = [1: KeywordsPage(page: 1, results: [], totalPages: 1)]

        let viewModel = SearchViewModel(repository: repository)
        viewModel.selectSuggestion(Keyword(id: 1, name: "toy"))

        await waitForContent(viewModel)

        guard case let .content(content) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(content.isEmpty)
    }

    @Test
    func testSelectSuggestionReplacesQueryAndSearchesImmediatelyWithoutDuplicateRequest() async {
        let repository = MockSearchRepository()
        let movie = Movie(id: 1, title: "Toy Story", overview: "", posterPath: nil, releaseDate: nil)
        repository.moviesPages["toy story"] = [1: Page(page: 1, results: [movie], totalPages: 1)]
        repository.personsPages["toy story"] = [1: PersonsPage(page: 1, results: [], totalPages: 1)]
        repository.keywordsPages["toy story"] = [1: KeywordsPage(page: 1, results: [], totalPages: 1)]

        let viewModel = SearchViewModel(repository: repository)
        let suggestion = Keyword(id: 1, name: "toy story")

        let start = Date()
        viewModel.selectSuggestion(suggestion)

        #expect(viewModel.query == "toy story")

        await waitForContent(viewModel)
        let elapsed = Date().timeIntervalSince(start)

        #expect(elapsed < 0.3) // well under the 400ms debounce window
        #expect(repository.moviesCallCount == 1)
        #expect(repository.personsCallCount == 1)
        #expect(repository.keywordsCallCount == 1)
    }

    @Test
    func testIdenticalNormalizedQueryDoesNotRepeatSearch() async {
        let repository = MockSearchRepository()
        repository.moviesPages["toy"] = [1: Page(page: 1, results: [], totalPages: 1)]
        repository.personsPages["toy"] = [1: PersonsPage(page: 1, results: [], totalPages: 1)]
        repository.keywordsPages["toy"] = [1: KeywordsPage(page: 1, results: [], totalPages: 1)]

        let viewModel = SearchViewModel(repository: repository)
        viewModel.query = "toy"
        await waitForContent(viewModel)

        let callsAfterFirst = repository.moviesCallCount
        viewModel.query = "  toy  " // same normalized query, only surrounding whitespace differs

        try? await Task.sleep(nanoseconds: 600_000_000)

        #expect(repository.moviesCallCount == callsAfterFirst)
    }

    @Test
    func testLoadMoreMoviesAppendsResults() async {
        let repository = MockSearchRepository()
        let first = Movie(id: 1, title: "First", overview: "", posterPath: nil, releaseDate: nil)
        let second = Movie(id: 2, title: "Second", overview: "", posterPath: nil, releaseDate: nil)
        repository.moviesPages["toy"] = [
            1: Page(page: 1, results: [first], totalPages: 2),
            2: Page(page: 2, results: [second], totalPages: 2),
        ]
        repository.personsPages["toy"] = [1: PersonsPage(page: 1, results: [], totalPages: 1)]
        repository.keywordsPages["toy"] = [1: KeywordsPage(page: 1, results: [], totalPages: 1)]

        let viewModel = SearchViewModel(repository: repository)
        viewModel.selectSuggestion(Keyword(id: 1, name: "toy"))
        await waitForContent(viewModel)

        viewModel.loadMoreMovies()
        await waitUntil {
            if case .content(let content) = viewModel.state { return content.movies.items.count == 2 }
            return false
        }

        guard case let .content(content) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(content.movies.items.map(\.id) == [1, 2])
        #expect(content.movies.currentPage == 2)
    }

    @Test
    func testLoadMorePersonsAppendsResults() async {
        let repository = MockSearchRepository()
        let first = Cast(id: 1, character: nil, name: "First", profilePath: nil)
        let second = Cast(id: 2, character: nil, name: "Second", profilePath: nil)
        repository.moviesPages["toy"] = [1: Page(page: 1, results: [], totalPages: 1)]
        repository.personsPages["toy"] = [
            1: PersonsPage(page: 1, results: [first], totalPages: 2),
            2: PersonsPage(page: 2, results: [second], totalPages: 2),
        ]
        repository.keywordsPages["toy"] = [1: KeywordsPage(page: 1, results: [], totalPages: 1)]

        let viewModel = SearchViewModel(repository: repository)
        viewModel.selectSuggestion(Keyword(id: 1, name: "toy"))
        await waitForContent(viewModel)

        viewModel.loadMorePersons()
        await waitUntil {
            if case .content(let content) = viewModel.state { return content.persons.items.count == 2 }
            return false
        }

        guard case let .content(content) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(content.persons.items.map(\.id) == [1, 2])
        #expect(content.persons.currentPage == 2)
    }

    @Test
    func testLoadMoreSuggestionsAppendsResults() async {
        let repository = MockSearchRepository()
        let first = Keyword(id: 1, name: "First")
        let second = Keyword(id: 2, name: "Second")
        repository.moviesPages["toy"] = [1: Page(page: 1, results: [], totalPages: 1)]
        repository.personsPages["toy"] = [1: PersonsPage(page: 1, results: [], totalPages: 1)]
        repository.keywordsPages["toy"] = [
            1: KeywordsPage(page: 1, results: [first], totalPages: 2),
            2: KeywordsPage(page: 2, results: [second], totalPages: 2),
        ]

        let viewModel = SearchViewModel(repository: repository)
        viewModel.selectSuggestion(Keyword(id: 1, name: "toy"))
        await waitForContent(viewModel)

        viewModel.loadMoreSuggestions()
        await waitUntil {
            if case .content(let content) = viewModel.state { return content.suggestions.items.count == 2 }
            return false
        }

        guard case let .content(content) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(content.suggestions.items.map(\.id) == [1, 2])
    }

    @Test
    func testConcurrentLoadMoreCallsOnlyTriggerOneRequest() async {
        let repository = MockSearchRepository()
        let first = Movie(id: 1, title: "First", overview: "", posterPath: nil, releaseDate: nil)
        let second = Movie(id: 2, title: "Second", overview: "", posterPath: nil, releaseDate: nil)
        repository.moviesPages["toy"] = [
            1: Page(page: 1, results: [first], totalPages: 2),
            2: Page(page: 2, results: [second], totalPages: 2),
        ]
        repository.personsPages["toy"] = [1: PersonsPage(page: 1, results: [], totalPages: 1)]
        repository.keywordsPages["toy"] = [1: KeywordsPage(page: 1, results: [], totalPages: 1)]
        repository.moviesDelayByQuery["toy"] = 150_000_000

        let viewModel = SearchViewModel(repository: repository)
        viewModel.selectSuggestion(Keyword(id: 1, name: "toy"))
        await waitForContent(viewModel)

        let callsBeforePagination = repository.moviesCallCount
        viewModel.loadMoreMovies()
        viewModel.loadMoreMovies()
        viewModel.loadMoreMovies()

        await waitUntil(timeout: 3) {
            if case .content(let content) = viewModel.state { return content.movies.items.count == 2 }
            return false
        }

        #expect(repository.moviesCallCount == callsBeforePagination + 1)
    }

    @Test
    func testLoadMoreDoesNothingAfterLastPage() async {
        let repository = MockSearchRepository()
        let first = Movie(id: 1, title: "First", overview: "", posterPath: nil, releaseDate: nil)
        repository.moviesPages["toy"] = [1: Page(page: 1, results: [first], totalPages: 1)]
        repository.personsPages["toy"] = [1: PersonsPage(page: 1, results: [], totalPages: 1)]
        repository.keywordsPages["toy"] = [1: KeywordsPage(page: 1, results: [], totalPages: 1)]

        let viewModel = SearchViewModel(repository: repository)
        viewModel.selectSuggestion(Keyword(id: 1, name: "toy"))
        await waitForContent(viewModel)

        let callsBefore = repository.moviesCallCount
        viewModel.loadMoreMovies()
        await Task.yield()

        #expect(repository.moviesCallCount == callsBefore)
    }

    @Test
    func testLoadMoreErrorKeepsExistingItemsAndDoesNotAdvancePage() async {
        let repository = MockSearchRepository()
        let first = Movie(id: 1, title: "First", overview: "", posterPath: nil, releaseDate: nil)
        repository.moviesPages["toy"] = [1: Page(page: 1, results: [first], totalPages: 2)]
        repository.moviesErrors["toy"] = [2: MockError.failed]
        repository.personsPages["toy"] = [1: PersonsPage(page: 1, results: [], totalPages: 1)]
        repository.keywordsPages["toy"] = [1: KeywordsPage(page: 1, results: [], totalPages: 1)]

        let viewModel = SearchViewModel(repository: repository)
        viewModel.selectSuggestion(Keyword(id: 1, name: "toy"))
        await waitForContent(viewModel)

        viewModel.loadMoreMovies()
        await waitUntil {
            if case .content(let content) = viewModel.state { return content.movies.pageError != nil }
            return false
        }

        guard case let .content(content) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(content.movies.items.map(\.id) == [1])
        #expect(content.movies.currentPage == 1)
        #expect(content.movies.isLoadingNextPage == false)
        #expect(content.movies.pageError != nil)
    }

    @Test
    func testLoadMoreDoesNotDuplicateOverlappingItems() async {
        let repository = MockSearchRepository()
        let first = Movie(id: 1, title: "First", overview: "", posterPath: nil, releaseDate: nil)
        let duplicateOfFirst = Movie(id: 1, title: "First", overview: "", posterPath: nil, releaseDate: nil)
        let second = Movie(id: 2, title: "Second", overview: "", posterPath: nil, releaseDate: nil)
        repository.moviesPages["toy"] = [
            1: Page(page: 1, results: [first], totalPages: 2),
            2: Page(page: 2, results: [duplicateOfFirst, second], totalPages: 2),
        ]
        repository.personsPages["toy"] = [1: PersonsPage(page: 1, results: [], totalPages: 1)]
        repository.keywordsPages["toy"] = [1: KeywordsPage(page: 1, results: [], totalPages: 1)]

        let viewModel = SearchViewModel(repository: repository)
        viewModel.selectSuggestion(Keyword(id: 1, name: "toy"))
        await waitForContent(viewModel)

        viewModel.loadMoreMovies()
        await waitUntil {
            if case .content(let content) = viewModel.state { return content.movies.currentPage == 2 }
            return false
        }

        guard case let .content(content) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(content.movies.items.map(\.id) == [1, 2])
    }

    @Test
    func testNewQueryResetsPaginationForAllSections() async {
        let repository = MockSearchRepository()
        let movie1 = Movie(id: 1, title: "First", overview: "", posterPath: nil, releaseDate: nil)
        let movie2 = Movie(id: 2, title: "Second", overview: "", posterPath: nil, releaseDate: nil)
        repository.moviesPages["toy"] = [
            1: Page(page: 1, results: [movie1], totalPages: 2),
            2: Page(page: 2, results: [movie2], totalPages: 2),
        ]
        repository.personsPages["toy"] = [1: PersonsPage(page: 1, results: [], totalPages: 1)]
        repository.keywordsPages["toy"] = [1: KeywordsPage(page: 1, results: [], totalPages: 1)]

        let freshMovie = Movie(id: 3, title: "Cars", overview: "", posterPath: nil, releaseDate: nil)
        repository.moviesPages["cars"] = [1: Page(page: 1, results: [freshMovie], totalPages: 5)]
        repository.personsPages["cars"] = [1: PersonsPage(page: 1, results: [], totalPages: 1)]
        repository.keywordsPages["cars"] = [1: KeywordsPage(page: 1, results: [], totalPages: 1)]

        let viewModel = SearchViewModel(repository: repository)
        viewModel.selectSuggestion(Keyword(id: 1, name: "toy"))
        await waitForContent(viewModel)

        viewModel.loadMoreMovies()
        await waitUntil {
            if case .content(let content) = viewModel.state { return content.movies.currentPage == 2 }
            return false
        }

        viewModel.selectSuggestion(Keyword(id: 2, name: "cars"))
        await waitUntil {
            if case .content(let content) = viewModel.state { return content.query == "cars" }
            return false
        }

        guard case let .content(content) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(content.movies.currentPage == 1)
        #expect(content.movies.totalPages == 5)
        #expect(content.movies.items.map(\.id) == [3])
    }

    @Test
    func testPartialResultsAreNotConsideredEmpty() {
        var content = SearchContent(query: "toy")
        content.movies.items = [Movie(id: 1, title: "Toy", overview: "", posterPath: nil, releaseDate: nil)]

        #expect(content.isEmpty == false)
    }
}

@MainActor
private func waitForContent(_ viewModel: SearchViewModel, timeout: TimeInterval = 3) async {
    await waitUntil(timeout: timeout) {
        if case .content = viewModel.state { return true }
        if case .error = viewModel.state { return true }
        return false
    }
}

@MainActor
private func waitUntil(timeout: TimeInterval = 3, _ condition: () -> Bool) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() && Date() < deadline {
        await Task.yield()
    }
}
