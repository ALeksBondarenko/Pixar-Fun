//
//  MovieDetailsViewModelTests.swift
//  Movie ExplorerTests
//
// Created by Александр Бондаренко on 07.03.2026.
//

import Testing
@testable import Movie_Explorer
import Foundation

@MainActor
struct MovieDetailsViewModelTests {

    final class MockMovieDetailRepository: MovieDetailRepository {

        var details: MovieDetails?
        var status: MovieStatus?
        var statusError: Error?
        var images: [Frame] = []
        var videos: [Video] = []
        var casts: [Cast] = []

        var favoriteResult: Bool = false
        var watchLaterResult: Bool = false

        /// Thrown once by the toggle methods, then cleared — simulates AuthError.notAuthenticated
        /// on the first attempt, followed by success after a login retry.
        var toggleError: Error?

        var error: Error?

        // Defaults to an empty, single-page result so every existing test that doesn't
        // care about similar movies doesn't have to configure it explicitly.
        var similarPages: [Int: Page] = [1: Page(page: 1, results: [], totalPages: 1)]
        var similarErrors: [Int: Error] = [:]
        var similarDelayNanosecondsByPage: [Int: UInt64] = [:]
        private(set) var requestedSimilarPages: [Int] = []

        func getDetailsOfMovie(movieId: Int) async throws -> MovieDetails {
            if let error = error {
                throw error
            }
            guard let details = details else {
                throw MockError.missingData
            }
            return details
        }

        func addToFavorites(movieId: Int) async throws -> Bool {
            if let toggleError = toggleError {
                self.toggleError = nil
                throw toggleError
            }
            if let error = error {
                throw error
            }
            return favoriteResult
        }

        func removeToFavorites(movieId: Int) async throws -> Bool {
            if let toggleError = toggleError {
                self.toggleError = nil
                throw toggleError
            }
            if let error = error {
                throw error
            }
            return favoriteResult
        }

        func addToWatchLater(movieId: Int) async throws -> Bool {
            if let toggleError = toggleError {
                self.toggleError = nil
                throw toggleError
            }
            if let error = error {
                throw error
            }
            return watchLaterResult
        }

        func removeToWatchLater(movieId: Int) async throws -> Bool {
            if let toggleError = toggleError {
                self.toggleError = nil
                throw toggleError
            }
            if let error = error {
                throw error
            }
            return watchLaterResult
        }

        func getMovieStatus(movieId: Int) async throws -> MovieStatus {
            if let statusError = statusError {
                throw statusError
            }
            if let error = error {
                throw error
            }
            guard let status = status else {
                throw MockError.missingData
            }
            return status
        }

        func getImages(movieId: Int) async throws -> [Frame] {
            if let error = error {
                throw error
            }
            return images
        }

        func getVideos(movieId: Int) async throws -> [Video] {
            if let error = error {
                throw error
            }
            return videos
        }

        func getCast(movieId: Int) async throws -> [Cast] {
            if let error = error {
                throw error
            }
            return casts
        }

        func getSimilar(movieId: Int, page: Int) async throws -> Page {
            requestedSimilarPages.append(page)
            if let delay = similarDelayNanosecondsByPage[page], delay > 0 {
                try await Task.sleep(nanoseconds: delay)
            }
            if let error = error {
                throw error
            }
            if let error = similarErrors[page] {
                throw error
            }
            guard let result = similarPages[page] else {
                Issue.record("Similar page \(page) not found")
                throw MockError.missingData
            }
            return result
        }
    }

    final class MockAuthRepository: AuthRepository {
        var accountId: Int?
        var loginError: Error?
        var loginCallCount = 0

        var isLoggedIn: Bool { accountId != nil }

        func currentAccountId() -> Int? {
            accountId
        }

        func login() async throws {
            loginCallCount += 1
            if let loginError {
                throw loginError
            }
            accountId = accountId ?? 1
        }

        func logout() {
            accountId = nil
        }
    }

    enum MockError: Error {
        case missingData
        case failed
    }

    let movie = Movie(id: 1, title: "Toy Story", overview: "overview", posterPath: nil, releaseDate: nil)
    let similarMovie1 = Movie(id: 101, title: "A Bug's Life", overview: "", posterPath: nil, releaseDate: nil)
    let similarMovie2 = Movie(id: 102, title: "Monsters, Inc.", overview: "", posterPath: nil, releaseDate: nil)
    let similarMovie3 = Movie(id: 103, title: "Finding Nemo", overview: "", posterPath: nil, releaseDate: nil)

    private func makeDetails() -> MovieDetails {
        MovieDetails(
            id: 1,
            title: "Toy Story",
            overview: "overview",
            genres: [],
            budget: 0,
            revenue: 0,
            status: "Released",
            releaseDate: Date(),
            backdropPath: "backdrop",
            posterPath: nil,
            voteAverage: 8.5
        )
    }

    @Test
    func testRequestDetailsSuccess() async {
        let repository = MockMovieDetailRepository()
        let authRepository = MockAuthRepository()
        let details = makeDetails()
        let status = MovieStatus(id: 1, favorite: true, watchlist: false)
        let frames = [Frame(filePath: "frame1")]
        let videos = [
            Video(key: "key1", site: "YouTube", type: "Trailer", official: true),
            Video(key: "key2", site: "YouTube", type: "Teaser", official: false)
        ]
        let casts = [Cast(id: 1, character: "Woody", name: "Tom Hanks", profilePath: nil)]

        repository.details = details
        repository.status = status
        repository.images = frames
        repository.videos = videos
        repository.casts = casts
        repository.similarPages[1] = Page(page: 1, results: [similarMovie1], totalPages: 1)

        let viewModel = MovieDetailsViewModel(repository: repository, authRepository: authRepository, movie: movie)

        viewModel.requestDetails()

        await waitForFinalState(viewModel: viewModel)

        switch viewModel.state {
        case .success(let loadedDetails, let loadedFrames, let loadedVideos, let loadedCasts, let favorite, let watchLater, let similarMovies, let error):
            #expect(loadedDetails == details)
            #expect(loadedFrames == frames)
            #expect(loadedVideos.map { $0.key } == [videos[0].key]) // только Trailer
            #expect(loadedCasts == casts)
            #expect(favorite == status.favorite)
            #expect(watchLater == status.watchlist)
            #expect(similarMovies == [similarMovie1])
            #expect(error == nil)
        default:
            Issue.record("Expected success state")
        }
    }

    @Test
    func testRequestDetailsWhenNotAuthenticatedDefaultsFavoriteAndWatchLaterToFalse() async {
        let repository = MockMovieDetailRepository()
        let authRepository = MockAuthRepository()
        repository.details = makeDetails()
        repository.statusError = AuthError.notAuthenticated

        let viewModel = MovieDetailsViewModel(repository: repository, authRepository: authRepository, movie: movie)

        viewModel.requestDetails()

        await waitForFinalState(viewModel: viewModel)

        switch viewModel.state {
        case .success(_, _, _, _, let favorite, let watchLater, _, _):
            #expect(favorite == false)
            #expect(watchLater == false)
        default:
            Issue.record("Expected success state with default favorite/watchLater when not authenticated")
        }
    }

    @Test
    func testRequestDetailsFailureSetsFailureState() async {
        let repository = MockMovieDetailRepository()
        let authRepository = MockAuthRepository()
        repository.error = MockError.failed

        let viewModel = MovieDetailsViewModel(repository: repository, authRepository: authRepository, movie: movie)

        viewModel.requestDetails()

        await waitForFinalState(viewModel: viewModel)

        switch viewModel.state {
        case .failure(let error):
            if case MockError.failed = error {
                // ok
            } else {
                Issue.record("Unexpected error type")
            }
        default:
            Issue.record("Expected failure state")
        }
    }

    @Test
    func testToggleFavoritesFromSuccessToOpposite() async {
        let repository = MockMovieDetailRepository()
        let authRepository = MockAuthRepository()
        authRepository.accountId = 1
        let frames = [Frame(filePath: "frame1")]
        let videos = [Video(key: "key1", site: "YouTube", type: "Trailer", official: true)]
        let casts = [Cast(id: 1, character: "Woody", name: "Tom Hanks", profilePath: nil)]

        repository.details = makeDetails()
        repository.status = MovieStatus(id: 1, favorite: false, watchlist: false)
        repository.images = frames
        repository.videos = videos
        repository.casts = casts
        repository.favoriteResult = true

        let viewModel = MovieDetailsViewModel(repository: repository, authRepository: authRepository, movie: movie)

        viewModel.requestDetails()
        await waitForFinalState(viewModel: viewModel)

        viewModel.toggleFavorites()
        await waitForFavoriteToggleToSettle(viewModel: viewModel)

        switch viewModel.state {
        case .success(_, _, _, _, let favorite, _, _, _):
            #expect(favorite == true)
        default:
            Issue.record("Expected success state after toggling favorites")
        }
    }

    @Test
    func testToggleFavoritesFailureChangesToFailureState() async {
        let repository = MockMovieDetailRepository()
        let authRepository = MockAuthRepository()
        authRepository.accountId = 1
        let frames = [Frame(filePath: "frame1")]
        let videos = [Video(key: "key1", site: "YouTube", type: "Trailer", official: true)]
        let casts = [Cast(id: 1, character: "Woody", name: "Tom Hanks", profilePath: nil)]

        repository.details = makeDetails()
        repository.status = MovieStatus(id: 1, favorite: false, watchlist: false)
        repository.images = frames
        repository.videos = videos
        repository.casts = casts

        let viewModel = MovieDetailsViewModel(repository: repository, authRepository: authRepository, movie: movie)

        viewModel.requestDetails()
        await waitForFinalState(viewModel: viewModel)

        repository.error = MockError.failed

        viewModel.toggleFavorites()
        await waitForFailureState(viewModel: viewModel)

        switch viewModel.state {
        case .failure(let error):
            if case MockError.failed = error {
                // ok
            } else {
                Issue.record("Unexpected error type")
            }
        default:
            Issue.record("Expected failure state after failed toggleFavorites")
        }
    }

    @Test
    func testToggleFavoritesRetriesAfterLoginWhenNotAuthenticated() async {
        let repository = MockMovieDetailRepository()
        let authRepository = MockAuthRepository()
        let frames = [Frame(filePath: "frame1")]
        let videos = [Video(key: "key1", site: "YouTube", type: "Trailer", official: true)]
        let casts = [Cast(id: 1, character: "Woody", name: "Tom Hanks", profilePath: nil)]

        repository.details = makeDetails()
        repository.statusError = AuthError.notAuthenticated
        repository.images = frames
        repository.videos = videos
        repository.casts = casts
        repository.favoriteResult = true
        repository.toggleError = AuthError.notAuthenticated

        let viewModel = MovieDetailsViewModel(repository: repository, authRepository: authRepository, movie: movie)

        viewModel.requestDetails()
        await waitForFinalState(viewModel: viewModel)

        viewModel.toggleFavorites()
        await waitForFavoriteToggleToSettle(viewModel: viewModel)

        #expect(authRepository.loginCallCount == 1)
        switch viewModel.state {
        case .success(_, _, _, _, let favorite, _, _, _):
            #expect(favorite == true)
        default:
            Issue.record("Expected success state after login retry")
        }
    }

    @Test
    func testToggleFavoritesFailureWhenLoginCancelled() async {
        let repository = MockMovieDetailRepository()
        let authRepository = MockAuthRepository()
        authRepository.loginError = AuthError.cancelled
        let frames = [Frame(filePath: "frame1")]
        let videos = [Video(key: "key1", site: "YouTube", type: "Trailer", official: true)]
        let casts = [Cast(id: 1, character: "Woody", name: "Tom Hanks", profilePath: nil)]

        repository.details = makeDetails()
        repository.statusError = AuthError.notAuthenticated
        repository.images = frames
        repository.videos = videos
        repository.casts = casts
        repository.toggleError = AuthError.notAuthenticated

        let viewModel = MovieDetailsViewModel(repository: repository, authRepository: authRepository, movie: movie)

        viewModel.requestDetails()
        await waitForFinalState(viewModel: viewModel)

        viewModel.toggleFavorites()
        await waitForFailureState(viewModel: viewModel)

        switch viewModel.state {
        case .failure(let error):
            if case AuthError.cancelled = error {
                // ok
            } else {
                Issue.record("Unexpected error type: \(error)")
            }
        default:
            Issue.record("Expected failure state when login is cancelled")
        }
    }

    @Test
    func testToggleWatchLaterFromSuccessToOpposite() async {
        let repository = MockMovieDetailRepository()
        let authRepository = MockAuthRepository()
        authRepository.accountId = 1
        let frames = [Frame(filePath: "frame1")]
        let videos = [Video(key: "key1", site: "YouTube", type: "Trailer", official: true)]
        let casts = [Cast(id: 1, character: "Woody", name: "Tom Hanks", profilePath: nil)]

        repository.details = makeDetails()
        repository.status = MovieStatus(id: 1, favorite: false, watchlist: false)
        repository.images = frames
        repository.videos = videos
        repository.casts = casts
        repository.watchLaterResult = true

        let viewModel = MovieDetailsViewModel(repository: repository, authRepository: authRepository, movie: movie)

        viewModel.requestDetails()
        await waitForFinalState(viewModel: viewModel)

        viewModel.toggleWatchLater()
        await waitForWatchLaterToggleToSettle(viewModel: viewModel)

        switch viewModel.state {
        case .success(_, _, _, _, _, let watchLater, _, _):
            #expect(watchLater == true)
        default:
            Issue.record("Expected success state after toggling watch later")
        }
    }

    @Test
    func testToggleWatchLaterFailureChangesToFailureState() async {
        let repository = MockMovieDetailRepository()
        let authRepository = MockAuthRepository()
        authRepository.accountId = 1
        let frames = [Frame(filePath: "frame1")]
        let videos = [Video(key: "key1", site: "YouTube", type: "Trailer", official: true)]
        let casts = [Cast(id: 1, character: "Woody", name: "Tom Hanks", profilePath: nil)]

        repository.details = makeDetails()
        repository.status = MovieStatus(id: 1, favorite: false, watchlist: false)
        repository.images = frames
        repository.videos = videos
        repository.casts = casts

        let viewModel = MovieDetailsViewModel(repository: repository, authRepository: authRepository, movie: movie)

        viewModel.requestDetails()
        await waitForFinalState(viewModel: viewModel)

        repository.error = MockError.failed

        viewModel.toggleWatchLater()
        await waitForFailureState(viewModel: viewModel)

        switch viewModel.state {
        case .failure(let error):
            if case MockError.failed = error {
                // ok
            } else {
                Issue.record("Unexpected error type")
            }
        default:
            Issue.record("Expected failure state after failed toggleWatchLater")
        }
    }

    @Test
    func testToggleFavoritesDoesNothingWhenNotSuccess() async {
        let repository = MockMovieDetailRepository()
        let authRepository = MockAuthRepository()
        let viewModel = MovieDetailsViewModel(repository: repository, authRepository: authRepository, movie: movie)

        viewModel.toggleFavorites()

        switch viewModel.state {
        case .loading:
            break
        default:
            Issue.record("Expected loading state when toggling favorites outside of success")
        }
    }

    @Test
    func testToggleWatchLaterDoesNothingWhenNotSuccess() async {
        let repository = MockMovieDetailRepository()
        let authRepository = MockAuthRepository()
        let viewModel = MovieDetailsViewModel(repository: repository, authRepository: authRepository, movie: movie)

        viewModel.toggleWatchLater()

        switch viewModel.state {
        case .loading:
            // ok, состояние не изменилось
            break
        default:
            Issue.record("Expected loading state when toggling watch later outside of success")
        }
    }

    // MARK: - Similar movies

    @Test
    func testLoadMoreSimilarAppendsResults() async {
        let repository = MockMovieDetailRepository()
        repository.details = makeDetails()
        repository.status = MovieStatus(id: 1, favorite: false, watchlist: false)
        repository.similarPages[1] = Page(page: 1, results: [similarMovie1], totalPages: 2)
        repository.similarPages[2] = Page(page: 2, results: [similarMovie2], totalPages: 2)

        let viewModel = MovieDetailsViewModel(repository: repository, authRepository: MockAuthRepository(), movie: movie)
        viewModel.requestDetails()
        await waitForFinalState(viewModel: viewModel)

        viewModel.loadMoreSimilar()
        await waitUntil {
            if case .success(_, _, _, _, _, _, let similarMovies, _) = viewModel.state {
                return similarMovies.count == 2
            }
            return false
        }

        guard case .success(_, _, _, _, _, _, let similarMovies, let error) = viewModel.state else {
            Issue.record("Expected success state")
            return
        }
        #expect(similarMovies == [similarMovie1, similarMovie2])
        #expect(error == nil)
    }

    @Test
    func testLoadMoreSimilarDoesNothingAfterLastPage() async {
        let repository = MockMovieDetailRepository()
        repository.details = makeDetails()
        repository.status = MovieStatus(id: 1, favorite: false, watchlist: false)
        repository.similarPages[1] = Page(page: 1, results: [similarMovie1], totalPages: 1)

        let viewModel = MovieDetailsViewModel(repository: repository, authRepository: MockAuthRepository(), movie: movie)
        viewModel.requestDetails()
        await waitForFinalState(viewModel: viewModel)

        let callsBefore = repository.requestedSimilarPages.count
        viewModel.loadMoreSimilar()
        await Task.yield()

        #expect(repository.requestedSimilarPages.count == callsBefore)
    }

    @Test
    func testLoadMoreSimilarFailurePreservesExistingSimilarMovies() async {
        let repository = MockMovieDetailRepository()
        repository.details = makeDetails()
        repository.status = MovieStatus(id: 1, favorite: false, watchlist: false)
        repository.similarPages[1] = Page(page: 1, results: [similarMovie1], totalPages: 2)
        repository.similarErrors[2] = MockError.failed

        let viewModel = MovieDetailsViewModel(repository: repository, authRepository: MockAuthRepository(), movie: movie)
        viewModel.requestDetails()
        await waitForFinalState(viewModel: viewModel)

        viewModel.loadMoreSimilar()
        await waitUntil {
            if case .success(_, _, _, _, _, _, _, let error) = viewModel.state {
                return error != nil
            }
            return false
        }

        guard case .success(_, _, _, _, _, _, let similarMovies, let error) = viewModel.state else {
            Issue.record("Expected success state with a non-blocking pagination error")
            return
        }
        #expect(similarMovies == [similarMovie1])
        #expect(error != nil)
    }

    @Test
    func testClearErrorKeepsSimilarMoviesAndRemovesError() async {
        let repository = MockMovieDetailRepository()
        repository.details = makeDetails()
        repository.status = MovieStatus(id: 1, favorite: false, watchlist: false)
        repository.similarPages[1] = Page(page: 1, results: [similarMovie1], totalPages: 2)
        repository.similarErrors[2] = MockError.failed

        let viewModel = MovieDetailsViewModel(repository: repository, authRepository: MockAuthRepository(), movie: movie)
        viewModel.requestDetails()
        await waitForFinalState(viewModel: viewModel)

        viewModel.loadMoreSimilar()
        await waitUntil {
            if case .success(_, _, _, _, _, _, _, let error) = viewModel.state {
                return error != nil
            }
            return false
        }

        viewModel.clearError()

        guard case .success(_, _, _, _, _, _, let similarMovies, let error) = viewModel.state else {
            Issue.record("Expected success state after clearing error")
            return
        }
        #expect(similarMovies == [similarMovie1])
        #expect(error == nil)
    }

    @Test
    func testConcurrentLoadMoreSimilarDoesNotSkipOrDuplicatePages() async {
        let repository = MockMovieDetailRepository()
        repository.details = makeDetails()
        repository.status = MovieStatus(id: 1, favorite: false, watchlist: false)
        repository.similarPages[1] = Page(page: 1, results: [similarMovie1], totalPages: 3)
        repository.similarPages[2] = Page(page: 2, results: [similarMovie2], totalPages: 3)
        repository.similarPages[3] = Page(page: 3, results: [similarMovie3], totalPages: 3)
        repository.similarDelayNanosecondsByPage[2] = 100_000_000

        let viewModel = MovieDetailsViewModel(repository: repository, authRepository: MockAuthRepository(), movie: movie)
        viewModel.requestDetails()
        await waitForFinalState(viewModel: viewModel)

        // Simulates duplicate onAppear firing for the last poster before the first
        // page-2 request has resolved.
        viewModel.loadMoreSimilar()
        viewModel.loadMoreSimilar()

        await waitUntil(timeout: 3) {
            if case .success(_, _, _, _, _, _, let similarMovies, _) = viewModel.state {
                return similarMovies.count == 2
            }
            return false
        }

        guard case .success(_, _, _, _, _, _, let similarMovies, let error) = viewModel.state else {
            Issue.record("Expected success state")
            return
        }
        #expect(similarMovies == [similarMovie1, similarMovie2])
        #expect(error == nil)

        // Page 2 must not have been skipped in favor of page 3.
        viewModel.loadMoreSimilar()
        await waitUntil(timeout: 3) {
            if case .success(_, _, _, _, _, _, let similarMovies, _) = viewModel.state {
                return similarMovies.count == 3
            }
            return false
        }
        guard case .success(_, _, _, _, _, _, let finalSimilarMovies, _) = viewModel.state else {
            Issue.record("Expected success state")
            return
        }
        #expect(finalSimilarMovies == [similarMovie1, similarMovie2, similarMovie3])
    }
}

@MainActor
private func waitForFinalState(viewModel: MovieDetailsViewModel) async {
    while true {
        switch viewModel.state {
        case .loading:
            await Task.yield()
        case .success, .failure:
            return
        }
    }
}

// `toggleFavorites`/`toggleWatchLater` transition .success -> .success (or .failure)
// without ever passing through .loading, so waitForFinalState (which only watches for
// a .loading exit) returns immediately before the toggle's async work has run. These
// wait for the actual outcome instead, bounded by a timeout so a genuine bug still fails
// the test rather than hanging it.
@MainActor
private func waitForFavoriteToggleToSettle(viewModel: MovieDetailsViewModel, timeout: TimeInterval = 3) async {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if case .success(_, _, _, _, true, _, _, _) = viewModel.state { return }
        if case .failure = viewModel.state { return }
        await Task.yield()
    }
}

@MainActor
private func waitForWatchLaterToggleToSettle(viewModel: MovieDetailsViewModel, timeout: TimeInterval = 3) async {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if case .success(_, _, _, _, _, true, _, _) = viewModel.state { return }
        if case .failure = viewModel.state { return }
        await Task.yield()
    }
}

@MainActor
private func waitForFailureState(viewModel: MovieDetailsViewModel, timeout: TimeInterval = 3) async {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if case .failure = viewModel.state { return }
        await Task.yield()
    }
}

@MainActor
private func waitUntil(timeout: TimeInterval = 3, _ condition: () -> Bool) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() && Date() < deadline {
        await Task.yield()
    }
}
