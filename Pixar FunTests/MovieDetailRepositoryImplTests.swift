//
//  MovieDetailRepositoryImplTests.swift
//  Pixar FunTests
//
//  Created by Александр Бондаренко on 07.03.2026.
//

import Testing
@testable import Pixar_Fun
import Foundation

@MainActor
struct MovieDetailRepositoryImplTests {

    final class MockMovieDetailsService: MovieDetailsServiceProtocol {

        var error: Error?

        var detailsResult: MovieDetails?
        var detailsMovieId: Int?

        var statusResult: MovieStatus?
        var statusMovieId: Int?

        var favoriteResponse = FavoriteResponse(success: true, statusCode: 1, statusMessage: "")
        var favoriteAccountId: Int?
        var favoriteRequest: FavoriteRequest?

        var watchLaterResponse = FavoriteResponse(success: true, statusCode: 1, statusMessage: "")
        var watchLaterAccountId: Int?
        var watchLaterRequest: WachListRequest?

        var imagesResult: ImagesResponse?
        var imagesMovieId: Int?

        var videosResult: VideosResponse?
        var videosMovieId: Int?

        var castsResult: CastsResponse?
        var castsMovieId: Int?

        func getDetails(movieId: Int) async throws -> MovieDetails {
            if let error = error {
                throw error
            }
            detailsMovieId = movieId
            guard let result = detailsResult else {
                Issue.record("detailsResult is not set")
                throw MockError.resultNotSet
            }
            return result
        }

        func getStatus(movieId: Int) async throws -> MovieStatus {
            if let error = error {
                throw error
            }
            statusMovieId = movieId
            guard let result = statusResult else {
                Issue.record("statusResult is not set")
                throw MockError.resultNotSet
            }
            return result
        }

        func changeFavoriteList(accountId: Int, request: FavoriteRequest) async throws -> FavoriteResponse {
            if let error = error {
                throw error
            }
            favoriteAccountId = accountId
            favoriteRequest = request
            return favoriteResponse
        }

        func changeWatchLater(accountId: Int, request: WachListRequest) async throws -> FavoriteResponse {
            if let error = error {
                throw error
            }
            watchLaterAccountId = accountId
            watchLaterRequest = request
            return watchLaterResponse
        }

        func getVideos(movieId: Int) async throws -> VideosResponse {
            if let error = error {
                throw error
            }
            videosMovieId = movieId
            guard let result = videosResult else {
                Issue.record("videosResult is not set")
                throw MockError.resultNotSet
            }
            return result
        }

        func getImages(movieId: Int) async throws -> ImagesResponse {
            if let error = error {
                throw error
            }
            imagesMovieId = movieId
            guard let result = imagesResult else {
                Issue.record("imagesResult is not set")
                throw MockError.resultNotSet
            }
            return result
        }

        func getCasts(movieId: Int) async throws -> CastsResponse {
            if let error = error {
                throw error
            }
            castsMovieId = movieId
            guard let result = castsResult else {
                Issue.record("castsResult is not set")
                throw MockError.resultNotSet
            }
            return result
        }
    }

    final class MockAuthRepository: AuthRepository {
        var accountId: Int?

        var isLoggedIn: Bool { accountId != nil }

        func currentAccountId() -> Int? {
            accountId
        }

        func login() async throws {
            accountId = accountId ?? 1
        }

        func logout() {
            accountId = nil
        }
    }

    enum MockError: Error {
        case resultNotSet
        case failed
    }

    @Test
    func testGetDetailsOfMovieDelegatesToService() async {
        let service = MockMovieDetailsService()
        let authRepository = MockAuthRepository()
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
        service.detailsResult = details

        let repository = MovieDetailRepositoryImpl(service: service, authRepository: authRepository)

        do {
            let result = try await repository.getDetailsOfMovie(movieId: 1)

            #expect(result == details)
            #expect(service.detailsMovieId == 1)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func testGetMovieStatusDelegatesToServiceWhenAuthenticated() async {
        let service = MockMovieDetailsService()
        let authRepository = MockAuthRepository()
        authRepository.accountId = 42
        let status = MovieStatus(id: 1, favorite: true, watchlist: false)
        service.statusResult = status

        let repository = MovieDetailRepositoryImpl(service: service, authRepository: authRepository)

        do {
            let result = try await repository.getMovieStatus(movieId: 10)

            #expect(result == status)
            #expect(service.statusMovieId == 10)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func testGetMovieStatusThrowsWhenNotAuthenticated() async {
        let service = MockMovieDetailsService()
        let authRepository = MockAuthRepository()
        let repository = MovieDetailRepositoryImpl(service: service, authRepository: authRepository)

        do {
            _ = try await repository.getMovieStatus(movieId: 10)
            Issue.record("Expected AuthError.notAuthenticated to be thrown")
        } catch AuthError.notAuthenticated {
            // ok
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }

        #expect(service.statusMovieId == nil)
    }

    @Test
    func testAddToFavoritesUsesServiceAndReturnsSuccess() async {
        let service = MockMovieDetailsService()
        let authRepository = MockAuthRepository()
        authRepository.accountId = 100
        service.favoriteResponse = FavoriteResponse(success: true, statusCode: 1, statusMessage: "ok")

        let repository = MovieDetailRepositoryImpl(service: service, authRepository: authRepository)

        do {
            let result = try await repository.addToFavorites(movieId: 5)

            #expect(result == true)
            #expect(service.favoriteAccountId == 100)
            #expect(service.favoriteRequest?.mediaId == 5)
            #expect(service.favoriteRequest?.favorite == true)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func testAddToFavoritesThrowsWhenNotAuthenticated() async {
        let service = MockMovieDetailsService()
        let authRepository = MockAuthRepository()
        let repository = MovieDetailRepositoryImpl(service: service, authRepository: authRepository)

        do {
            _ = try await repository.addToFavorites(movieId: 5)
            Issue.record("Expected AuthError.notAuthenticated to be thrown")
        } catch AuthError.notAuthenticated {
            // ok
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }

        #expect(service.favoriteRequest == nil)
    }

    @Test
    func testRemoveFromFavoritesUsesServiceAndReturnsSuccess() async {
        let service = MockMovieDetailsService()
        let authRepository = MockAuthRepository()
        authRepository.accountId = 200
        service.favoriteResponse = FavoriteResponse(success: true, statusCode: 1, statusMessage: "ok")

        let repository = MovieDetailRepositoryImpl(service: service, authRepository: authRepository)

        do {
            let result = try await repository.removeToFavorites(movieId: 7)

            #expect(result == true)
            #expect(service.favoriteAccountId == 200)
            #expect(service.favoriteRequest?.mediaId == 7)
            #expect(service.favoriteRequest?.favorite == false)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func testAddToWatchLaterUsesServiceAndReturnsSuccess() async {
        let service = MockMovieDetailsService()
        let authRepository = MockAuthRepository()
        authRepository.accountId = 300
        service.watchLaterResponse = FavoriteResponse(success: true, statusCode: 1, statusMessage: "ok")

        let repository = MovieDetailRepositoryImpl(service: service, authRepository: authRepository)

        do {
            let result = try await repository.addToWatchLater(movieId: 9)

            #expect(result == true)
            #expect(service.watchLaterAccountId == 300)
            #expect(service.watchLaterRequest?.mediaId == 9)
            #expect(service.watchLaterRequest?.watchlist == true)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func testRemoveFromWatchLaterUsesServiceAndReturnsSuccess() async {
        let service = MockMovieDetailsService()
        let authRepository = MockAuthRepository()
        authRepository.accountId = 400
        service.watchLaterResponse = FavoriteResponse(success: true, statusCode: 1, statusMessage: "ok")

        let repository = MovieDetailRepositoryImpl(service: service, authRepository: authRepository)

        do {
            let result = try await repository.removeToWatchLater(movieId: 11)

            #expect(result == true)
            #expect(service.watchLaterAccountId == 400)
            #expect(service.watchLaterRequest?.mediaId == 11)
            #expect(service.watchLaterRequest?.watchlist == false)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func testGetImagesDelegatesToService() async {
        let service = MockMovieDetailsService()
        let authRepository = MockAuthRepository()
        let frames = [Frame(filePath: "frame1"), Frame(filePath: "frame2")]
        service.imagesResult = ImagesResponse(backdrops: frames)

        let repository = MovieDetailRepositoryImpl(service: service, authRepository: authRepository)

        do {
            let result = try await repository.getImages(movieId: 50)

            #expect(result == frames)
            #expect(service.imagesMovieId == 50)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func testGetVideosDelegatesToService() async {
        let service = MockMovieDetailsService()
        let authRepository = MockAuthRepository()
        let videos = [
            Video(key: "key1", site: "YouTube", type: "Trailer", official: true),
            Video(key: "key2", site: "YouTube", type: "Teaser", official: false)
        ]
        service.videosResult = VideosResponse(results: videos)

        let repository = MovieDetailRepositoryImpl(service: service, authRepository: authRepository)

        do {
            let result = try await repository.getVideos(movieId: 60)

            #expect(result.map { $0.key } == videos.map { $0.key })
            #expect(service.videosMovieId == 60)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func testGetCastDelegatesToService() async {
        let service = MockMovieDetailsService()
        let authRepository = MockAuthRepository()
        let casts = [
            Cast(id: 1, character: "Woody", name: "Tom Hanks", profilePath: "path1"),
            Cast(id: 2, character: "Buzz", name: "Tim Allen", profilePath: "path2")
        ]
        service.castsResult = CastsResponse(cast: casts)

        let repository = MovieDetailRepositoryImpl(service: service, authRepository: authRepository)

        do {
            let result = try await repository.getCast(movieId: 70)

            #expect(result == casts)
            #expect(service.castsMovieId == 70)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func testRepositoryPropagatesServiceError() async {
        let service = MockMovieDetailsService()
        let authRepository = MockAuthRepository()
        service.error = MockError.failed
        let repository = MovieDetailRepositoryImpl(service: service, authRepository: authRepository)

        do {
            _ = try await repository.getDetailsOfMovie(movieId: 1)
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
