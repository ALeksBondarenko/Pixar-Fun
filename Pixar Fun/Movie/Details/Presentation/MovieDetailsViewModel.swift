//
//  MovieDetailsViewModel.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 09.12.2025.
//
import Foundation
import Combine

class MovieDetailsViewModel: ViewModel {
    private let repository: MovieDetailRepository
    let movie: Movie
    @Published private(set) var state: MovieDetailsState = .loading
    @Published private(set) var title: String = ""
    
    init(repository: MovieDetailRepository, movie: Movie) {
        self.repository = repository
        self.movie = movie
        self.title = movie.title
    }
    
    func requestDetails() {
        addTask { @MainActor in
            do {
                let movieDetails = try await self.repository.getDetailsOfMovie(movieId: self.movie.id)
                let status = try await self.repository.getMovieStatus(movieId: self.movie.id)
                let videos = try await self.repository.getVideos(movieId: self.movie.id).filter( { $0.type == "Trailer" })
                let images = try await self.repository.getImages(movieId: self.movie.id)
                let casts = try await self.repository.getCast(movieId: self.movie.id)
                self.state = .success(movieDetails, images, videos, casts, favorite: status.favorite, watchLater: status.watchlist)
            } catch {
                self.state = .failure(error)
            }
        }
    }
    
    func toggleFavorites() {
        addTask { @MainActor in
            do {
                if case .success(let movie, let images, let videos, let casts, let favorite, let watchLater) = self.state {
                    var isFvorite = favorite
                    if isFvorite {
                        isFvorite = try await !self.repository.removeToFavorites(movieId: self.movie.id)
                    } else {
                        isFvorite = try await self.repository.addToFavorites(movieId: self.movie.id)
                    }
                    self.state = .success(movie, images, videos, casts, favorite: isFvorite, watchLater: watchLater)
                }
            } catch {
                log(error.localizedDescription)
                self.state = .failure(error)
            }
        }
    }
    
    func toggleWatchLater() {
        addTask { @MainActor in
            do {
                if case .success(let movie, let images, let videos, let casts, let favorite, let watchLater) = self.state {
                    var isWatchLater = watchLater
                    if isWatchLater {
                        isWatchLater = try await !self.repository.removeToWatchLater(movieId: self.movie.id)
                    } else {
                        isWatchLater = try await self.repository.addToWatchLater(movieId: self.movie.id)
                    }
                    self.state = .success(movie, images, videos, casts, favorite: favorite, watchLater: isWatchLater)
                }
            } catch {
                log(error.localizedDescription)
                self.state = .failure(error)
            }
        }
    }
}
