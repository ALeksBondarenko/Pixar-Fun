//
//  SearchViewModel.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 03.01.2026.
//

import Foundation
import Combine

class SearchViewModel: ViewModel {

    private static let minimumQueryLength = 3
    private static let debounceNanoseconds: UInt64 = 400_000_000

    private let repository: SearchRepository

    @Published var query: String = "" {
        didSet {
            guard query != oldValue else { return }
            scheduleSearch(for: query, immediate: false)
        }
    }
    @Published private(set) var state: SearchState = .idle

    private var lastQuery: String?
    private var requestToken = 0

    init(repository: SearchRepository) {
        self.repository = repository
    }

    func selectSuggestion(_ suggestion: Keyword) {
        let trimmed = suggestion.name.trimmingCharacters(in: .whitespacesAndNewlines)
        scheduleSearch(for: trimmed, immediate: true)
        if query != suggestion.name {
            query = suggestion.name
        }
    }

    func retry() {
        guard let lastQuery else { return }
        scheduleSearch(for: lastQuery, immediate: true, forceRestart: true)
    }

    func loadMoreMovies() {
        loadNextPage(\.movies) { [repository] query, page in
            let result = try await repository.searchMovies(query: query, page: page)
            return (result.results, result.page ?? page, result.totalPages)
        }
    }

    func loadMorePersons() {
        loadNextPage(\.persons) { [repository] query, page in
            let result = try await repository.searchPersons(query: query, page: page)
            return (result.results, result.page ?? page, result.totalPages)
        }
    }

    func loadMoreSuggestions() {
        loadNextPage(\.suggestions) { [repository] query, page in
            let result = try await repository.searchKeywords(query: query, page: page)
            return (result.results, result.page ?? page, result.totalPages)
        }
    }

    func retryMovies() {
        retryInitialLoad(\.movies) { [repository] query in
            let result = try await repository.searchMovies(query: query, page: 1)
            return (result.results, result.page ?? 1, result.totalPages)
        }
    }

    func retryPersons() {
        retryInitialLoad(\.persons) { [repository] query in
            let result = try await repository.searchPersons(query: query, page: 1)
            return (result.results, result.page ?? 1, result.totalPages)
        }
    }

    func retrySuggestions() {
        retryInitialLoad(\.suggestions) { [repository] query in
            let result = try await repository.searchKeywords(query: query, page: 1)
            return (result.results, result.page ?? 1, result.totalPages)
        }
    }

    // MARK: - Debounce & new query

    private func scheduleSearch(for rawText: String, immediate: Bool, forceRestart: Bool = false) {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= Self.minimumQueryLength else {
            cancelAllTasks()
            requestToken += 1
            lastQuery = nil
            state = .idle
            return
        }

        if !immediate && !forceRestart && trimmed == lastQuery {
            return
        }

        lastQuery = trimmed
        cancelAllTasks()
        requestToken += 1
        let token = requestToken
        state = .searching

        addTask { @MainActor in
            if !immediate {
                do {
                    try await Task.sleep(nanoseconds: Self.debounceNanoseconds)
                } catch {
                    return
                }
            }
            guard !Task.isCancelled, token == self.requestToken else { return }
            await self.performInitialSearch(query: trimmed, token: token)
        }
    }

    @MainActor
    private func performInitialSearch(query: String, token: Int) async {
        async let moviesResult = fetchResult { try await self.repository.searchMovies(query: query, page: 1) }
        async let personsResult = fetchResult { try await self.repository.searchPersons(query: query, page: 1) }
        async let keywordsResult = fetchResult { try await self.repository.searchKeywords(query: query, page: 1) }

        let movies = await moviesResult
        let persons = await personsResult
        let keywords = await keywordsResult

        guard token == self.requestToken else { return }

        var content = SearchContent(query: query)

        switch movies {
        case .success(let page):
            content.movies.items = page.results
            content.movies.currentPage = page.page ?? 1
            content.movies.totalPages = page.totalPages
        case .failure(let error):
            content.movies.initialError = error
        }

        switch persons {
        case .success(let page):
            content.persons.items = page.results
            content.persons.currentPage = page.page ?? 1
            content.persons.totalPages = page.totalPages
        case .failure(let error):
            content.persons.initialError = error
        }

        switch keywords {
        case .success(let page):
            content.suggestions.items = page.results
            content.suggestions.currentPage = page.page ?? 1
            content.suggestions.totalPages = page.totalPages
        case .failure(let error):
            content.suggestions.initialError = error
        }

        let allFailed = content.movies.initialError != nil
            && content.persons.initialError != nil
            && content.suggestions.initialError != nil

        if allFailed, let error = content.movies.initialError {
            log(error)
            state = .error(error)
        } else {
            state = .content(content)
        }
    }

    private func fetchResult<T>(_ operation: @Sendable () async throws -> T) async -> Result<T, Error> {
        do {
            return .success(try await operation())
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Pagination

    private func loadNextPage<Item: Identifiable>(
        _ keyPath: WritableKeyPath<SearchContent, SearchSectionState<Item>>,
        fetch: @escaping @Sendable (String, Int) async throws -> (items: [Item], currentPage: Int, totalPages: Int)
    ) {
        guard case .content(var content) = state else { return }
        let section = content[keyPath: keyPath]
        guard !section.isLoadingNextPage, section.canLoadMore else { return }

        let query = content.query
        let nextPage = section.currentPage + 1
        let token = requestToken

        content[keyPath: keyPath].isLoadingNextPage = true
        content[keyPath: keyPath].pageError = nil
        state = .content(content)

        addTask { @MainActor in
            do {
                let result = try await fetch(query, nextPage)
                self.appendPage(keyPath, token: token, items: result.items, currentPage: result.currentPage, totalPages: result.totalPages)
            } catch {
                self.failPage(keyPath, token: token, error: error)
            }
        }
    }

    @MainActor
    private func appendPage<Item: Identifiable>(
        _ keyPath: WritableKeyPath<SearchContent, SearchSectionState<Item>>,
        token: Int,
        items: [Item],
        currentPage: Int,
        totalPages: Int
    ) {
        guard token == requestToken, case .content(var content) = state else { return }
        let existingIDs = Set(content[keyPath: keyPath].items.map(\.id))
        let newItems = items.filter { !existingIDs.contains($0.id) }
        content[keyPath: keyPath].items.append(contentsOf: newItems)
        content[keyPath: keyPath].currentPage = currentPage
        content[keyPath: keyPath].totalPages = totalPages
        content[keyPath: keyPath].isLoadingNextPage = false
        state = .content(content)
    }

    @MainActor
    private func failPage<Item: Identifiable>(
        _ keyPath: WritableKeyPath<SearchContent, SearchSectionState<Item>>,
        token: Int,
        error: Error
    ) {
        guard token == requestToken, case .content(var content) = state else { return }
        log(error)
        content[keyPath: keyPath].isLoadingNextPage = false
        content[keyPath: keyPath].pageError = error
        state = .content(content)
    }

    private func retryInitialLoad<Item: Identifiable>(
        _ keyPath: WritableKeyPath<SearchContent, SearchSectionState<Item>>,
        fetch: @escaping @Sendable (String) async throws -> (items: [Item], currentPage: Int, totalPages: Int)
    ) {
        guard case .content(var content) = state else { return }
        guard content[keyPath: keyPath].initialError != nil, !content[keyPath: keyPath].isLoadingNextPage else { return }

        let query = content.query
        let token = requestToken

        content[keyPath: keyPath].isLoadingNextPage = true
        content[keyPath: keyPath].initialError = nil
        state = .content(content)

        addTask { @MainActor in
            do {
                let result = try await fetch(query)
                self.replaceFirstPage(keyPath, token: token, items: result.items, currentPage: result.currentPage, totalPages: result.totalPages)
            } catch {
                self.failInitialLoad(keyPath, token: token, error: error)
            }
        }
    }

    @MainActor
    private func replaceFirstPage<Item: Identifiable>(
        _ keyPath: WritableKeyPath<SearchContent, SearchSectionState<Item>>,
        token: Int,
        items: [Item],
        currentPage: Int,
        totalPages: Int
    ) {
        guard token == requestToken, case .content(var content) = state else { return }
        content[keyPath: keyPath].items = items
        content[keyPath: keyPath].currentPage = currentPage
        content[keyPath: keyPath].totalPages = totalPages
        content[keyPath: keyPath].isLoadingNextPage = false
        state = .content(content)
    }

    @MainActor
    private func failInitialLoad<Item: Identifiable>(
        _ keyPath: WritableKeyPath<SearchContent, SearchSectionState<Item>>,
        token: Int,
        error: Error
    ) {
        guard token == requestToken, case .content(var content) = state else { return }
        log(error)
        content[keyPath: keyPath].isLoadingNextPage = false
        content[keyPath: keyPath].initialError = error
        state = .content(content)
    }
}
