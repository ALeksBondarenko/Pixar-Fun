//
//  MovieDetailsViewModel.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 09.12.2025.
//
import Foundation
import Combine

class MovieDetailsViewModel: ViewModel {
    private let repository: MovieDetailRepository
    private let authRepository: AuthRepository
    let movie: Movie
    @Published private(set) var state: MovieDetailsState = .loading
    @Published private(set) var title: String = ""
    private var page: Int = 1
    private var totalPage: Int = 1

    init(repository: MovieDetailRepository, authRepository: AuthRepository, movie: Movie) {
        self.repository = repository
        self.authRepository = authRepository
        self.movie = movie
        self.title = movie.title
    }

    func requestDetails() {
        addTask { @MainActor in
            do {
                async let detailsResult = self.repository.getDetailsOfMovie(movieId: self.movie.id)
                async let videosResult = self.repository.getVideos(movieId: self.movie.id)
                async let imagesResult = self.repository.getImages(movieId: self.movie.id)
                async let castsResult = self.repository.getCast(movieId: self.movie.id)
                async let statusResult = self.currentMovieStatus()
                async let similarPageResult = self.repository.getSimilar(movieId: self.movie.id, page: 1)

                let (movieDetails, videos, images, casts, status, similarPage) = try await (detailsResult, videosResult, imagesResult, castsResult, statusResult, similarPageResult)
                self.page = 1
                self.totalPage = similarPage.totalPages
                
                self.state = .success(
                    movieDetails,
                    images,
                    videos.filter { $0.type == "Trailer" },
                    casts,
                    favorite: status?.favorite ?? false,
                    watchLater: status?.watchlist ?? false,
                    similarPage.results,
                    nil
                )
            } catch {
                self.state = .failure(error)
            }
        }
    }

    private func currentMovieStatus() async throws -> MovieStatus? {
        do {
            return try await self.repository.getMovieStatus(movieId: self.movie.id)
        } catch AuthError.notAuthenticated {
            return nil
        }
    }

    private func withAuthRetry<T>(_ operation: @Sendable () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch AuthError.notAuthenticated {
            try await authRepository.login()
            return try await operation()
        }
    }
    
    func loadMoreSimilar() {
        guard page < totalPage else { return }
        guard case .success(let movie, let photos, let videos, let casts, let favorite, let watchLater, let similarMovies, _) = state else { return }
        
        cancelAllTasks()
        
        addTask { @MainActor in
            do {
                let result = try await self.repository.getSimilar(movieId: self.movie.id, page: self.page + 1)
                self.page = self.page + 1
                self.totalPage = result.totalPages
                
                self.state = .success(movie, photos, videos, casts, favorite: favorite, watchLater: watchLater, similarMovies + result.results, nil)
            } catch is CancellationError {
                return
            } catch let urlError as URLError where urlError.code == .cancelled {
                return
            } catch {
                log(error)
                self.state = .success(movie, photos, videos, casts, favorite: favorite, watchLater: watchLater, similarMovies, error)
            }
        }
    }
    
    func clearError() {
        guard case .success(let movie, let photos, let videos, let casts, let favorite, let watchLater, let similarMovies, _) = state else { return }
        self.state = .success(movie, photos, videos, casts, favorite: favorite, watchLater: watchLater, similarMovies, nil)
    }

    func toggleFavorites() {
        addTask { @MainActor in
            guard case .success(let movie, let photos, let videos, let casts, let favorite, let watchLater, let similarMovies, _) = self.state else {
                return
            }
            do {
                let isFavorite = try await self.withAuthRetry {
                    if favorite {
                        return try await !self.repository.removeToFavorites(movieId: self.movie.id)
                    } else {
                        return try await self.repository.addToFavorites(movieId: self.movie.id)
                    }
                }
                self.state = .success(movie, photos, videos, casts, favorite: isFavorite, watchLater: watchLater, similarMovies, nil)
            } catch {
                log(error)
                self.state = .failure(error)
            }
        }
    }

    func toggleWatchLater() {
        addTask { @MainActor in
            guard case .success(let movie, let photos, let videos, let casts, let favorite, let watchLater, let similarMovies, _) = self.state else {
                return
            }
            do {
                let isWatchLater = try await self.withAuthRetry {
                    if watchLater {
                        return try await !self.repository.removeToWatchLater(movieId: self.movie.id)
                    } else {
                        return try await self.repository.addToWatchLater(movieId: self.movie.id)
                    }
                }
                self.state = .success(movie, photos, videos, casts, favorite: favorite, watchLater: isWatchLater, similarMovies, nil)
            } catch {
                log(error)
                self.state = .failure(error)
            }
        }
    }
}
