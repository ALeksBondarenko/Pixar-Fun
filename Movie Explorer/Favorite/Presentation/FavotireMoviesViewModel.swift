//
//  FavotireMoviesViewModel.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 30.12.2025.
//

import Foundation
import Combine

class FavotireMoviesViewModel: ViewModel {

    private let repository: FavoriteRepository
    private let authRepository: AuthRepository
    @Published private(set) var state: FavotireMoviesState = .idle

    private var movies: [Movie] = []
    private var currentPage: Int = 1
    private var maxPages: Int = 1

    init(repository: FavoriteRepository, authRepository: AuthRepository) {
        self.repository = repository
        self.authRepository = authRepository
    }

    func fetchFavotireMovies() {
        guard authRepository.isLoggedIn else {
            state = .unauthenticated
            return
        }
        if case .idle = state {
            state = .loading
            fetchPage(nextPage: currentPage)
        }
    }

    func login() {
        addTask { @MainActor in
            do {
                try await self.authRepository.login()
                self.state = .idle
                self.fetchFavotireMovies()
            } catch {
                log(error.localizedDescription)
                self.state = .unauthenticated
            }
        }
    }
    
    func refreshFavotireMovies() {
        state = .loading
        fetchPage(nextPage: 1)
    }
    
    func fetchMoreFavotireMovies() {
        guard currentPage < maxPages else { return }
        guard case .content(let movies, _) = state else { return }
        fetchPage(movies: movies, nextPage: currentPage + 1)
    }
    
    func reloadLastPage() {
        guard case .content(let movies, _) = state else { return }
        fetchPage(movies: movies, nextPage: currentPage + 1)
    }

    func clearError() {
        guard case .content(let movies, _) = state else { return }
        self.state = .content(movies, nil)
    }

    private func fetchPage(movies: [Movie] = [], nextPage: Int) {
        cancelAllTasks()

        addTask { @MainActor in
            do {
                let page = try await self.repository.fetchFavoriteMovies(page: nextPage)
                self.currentPage = page.page ?? nextPage
                self.maxPages = page.totalPages
                
                let allMovies = movies + page.results
                
                if allMovies.isEmpty {
                    self.state = .empty
                } else {
                    self.state = .content(allMovies, nil)
                }
            } catch is CancellationError {
                return
            } catch let urlError as URLError where urlError.code == .cancelled {
                return
            } catch {
                log(error.localizedDescription)
                self.state = .content(movies, error)
            }
        }
    }
}
