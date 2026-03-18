//
//  MovieDetailsViewModelTests.swift
//  Pixar FunTests
//
// Created by Александр Бондаренко on 07.03.2026.
//

import Testing
@testable import Pixar_Fun
import Foundation

@MainActor
struct MovieDetailsViewModelTests {
    
    final class MockMovieDetailRepository: MovieDetailRepository {
        
        var details: MovieDetails?
        var status: MovieStatus?
        var images: [Frame] = []
        var videos: [Video] = []
        var casts: [Cast] = []
        
        var favoriteResult: Bool = false
        var watchLaterResult: Bool = false
        
        var error: Error?
        
        func getDetailsOfMovie(movieId: Int) async throws -> MovieDetails {
            if let error = error {
                throw error
            }
            guard let details = details else {
                throw MockError.missingData
            }
            return details
        }
        
        func addToFavorites(accountId: Int, movieId: Int) async throws -> Bool {
            if let error = error {
                throw error
            }
            return favoriteResult
        }
        
        func removeToFavorites(accountId: Int, movieId: Int) async throws -> Bool {
            if let error = error {
                throw error
            }
            return favoriteResult
        }
        
        func addToWatchLater(accountId: Int, movieId: Int) async throws -> Bool {
            if let error = error {
                throw error
            }
            return watchLaterResult
        }
        
        func removeToWatchLater(accountId: Int, movieId: Int) async throws -> Bool {
            if let error = error {
                throw error
            }
            return watchLaterResult
        }
        
        func getMovieStatus(movieId: Int) async throws -> MovieStatus {
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
    }
    
    enum MockError: Error {
        case missingData
        case failed
    }
    
    let movie = Movie(id: 1, title: "Toy Story", overview: "overview", posterPath: nil, releaseDate: nil)
    
    @Test
    func testRequestDetailsSuccess() async {
        let repository = MockMovieDetailRepository()
        let details = MovieDetails(
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
        
        let viewModel = MovieDetailsViewModel(repository: repository, movie: movie)
        
        viewModel.requestDetails()
        
        await waitForFinalState(viewModel: viewModel)
        
        switch viewModel.state {
        case .success(let loadedDetails, let loadedFrames, let loadedVideos, let loadedCasts, let favorite, let watchLater):
            #expect(loadedDetails == details)
            #expect(loadedFrames == frames)
            #expect(loadedVideos.map { $0.key } == [videos[0].key]) // только Trailer
            #expect(loadedCasts == casts)
            #expect(favorite == status.favorite)
            #expect(watchLater == status.watchlist)
        default:
            Issue.record("Expected success state")
        }
    }
    
    @Test
    func testRequestDetailsFailureSetsFailureState() async {
        let repository = MockMovieDetailRepository()
        repository.error = MockError.failed
        
        let viewModel = MovieDetailsViewModel(repository: repository, movie: movie)
        
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
        let details = MovieDetails(
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
        let frames = [Frame(filePath: "frame1")]
        let videos = [Video(key: "key1", site: "YouTube", type: "Trailer", official: true)]
        let casts = [Cast(id: 1, character: "Woody", name: "Tom Hanks", profilePath: nil)]
        
        repository.details = details
        repository.status = MovieStatus(id: 1, favorite: false, watchlist: false)
        repository.images = frames
        repository.videos = videos
        repository.casts = casts
        repository.favoriteResult = true
        
        let viewModel = MovieDetailsViewModel(repository: repository, movie: movie)
        
        viewModel.requestDetails()
        await Task.yield()
        
        viewModel.toggleFavorites()
        await Task.yield()
        
        switch viewModel.state {
        case .success(_, _, _, _, let favorite, _):
            #expect(favorite == true)
        default:
            Issue.record("Expected success state after toggling favorites")
        }
    }
    
    @Test
    func testToggleFavoritesFailureChangesToFailureState() async {
        let repository = MockMovieDetailRepository()
        let details = MovieDetails(
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
        let frames = [Frame(filePath: "frame1")]
        let videos = [Video(key: "key1", site: "YouTube", type: "Trailer", official: true)]
        let casts = [Cast(id: 1, character: "Woody", name: "Tom Hanks", profilePath: nil)]
        
        repository.details = details
        repository.status = MovieStatus(id: 1, favorite: false, watchlist: false)
        repository.images = frames
        repository.videos = videos
        repository.casts = casts
        
        let viewModel = MovieDetailsViewModel(repository: repository, movie: movie)
        
        viewModel.requestDetails()
        await Task.yield()
        
        repository.error = MockError.failed
        
        viewModel.toggleFavorites()
        await Task.yield()
        
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
    func testToggleWatchLaterFromSuccessToOpposite() async {
        let repository = MockMovieDetailRepository()
        let details = MovieDetails(
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
        let frames = [Frame(filePath: "frame1")]
        let videos = [Video(key: "key1", site: "YouTube", type: "Trailer", official: true)]
        let casts = [Cast(id: 1, character: "Woody", name: "Tom Hanks", profilePath: nil)]
        
        repository.details = details
        repository.status = MovieStatus(id: 1, favorite: false, watchlist: false)
        repository.images = frames
        repository.videos = videos
        repository.casts = casts
        repository.watchLaterResult = true
        
        let viewModel = MovieDetailsViewModel(repository: repository, movie: movie)
        
        viewModel.requestDetails()
        await Task.yield()
        
        viewModel.toggleWatchLater()
        await Task.yield()
        
        switch viewModel.state {
        case .success(_, _, _, _, _, let watchLater):
            #expect(watchLater == true)
        default:
            Issue.record("Expected success state after toggling watch later")
        }
    }
    
    @Test
    func testToggleWatchLaterFailureChangesToFailureState() async {
        let repository = MockMovieDetailRepository()
        let details = MovieDetails(
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
        let frames = [Frame(filePath: "frame1")]
        let videos = [Video(key: "key1", site: "YouTube", type: "Trailer", official: true)]
        let casts = [Cast(id: 1, character: "Woody", name: "Tom Hanks", profilePath: nil)]
        
        repository.details = details
        repository.status = MovieStatus(id: 1, favorite: false, watchlist: false)
        repository.images = frames
        repository.videos = videos
        repository.casts = casts
        
        let viewModel = MovieDetailsViewModel(repository: repository, movie: movie)
        
        viewModel.requestDetails()
        await Task.yield()
        
        repository.error = MockError.failed
        
        viewModel.toggleWatchLater()
        await Task.yield()
        
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
        let viewModel = MovieDetailsViewModel(repository: repository, movie: movie)
        
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
        let viewModel = MovieDetailsViewModel(repository: repository, movie: movie)
        
        viewModel.toggleWatchLater()
        
        switch viewModel.state {
        case .loading:
            // ok, состояние не изменилось
            break
        default:
            Issue.record("Expected loading state when toggling watch later outside of success")
        }
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

