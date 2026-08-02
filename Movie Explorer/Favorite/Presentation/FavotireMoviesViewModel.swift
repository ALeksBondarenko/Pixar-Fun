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
        movies.removeAll()
        currentPage = 1
        state = .loading
        fetchPage(nextPage: currentPage)
    }
    
    func fetchMoreFavotireMovies() {
        if currentPage >= maxPages {
            return
        }
        currentPage = currentPage + 1
        fetchPage(nextPage: currentPage)
    }
    
    func reloadLastPage() {
        if case .error = state {
            fetchPage(nextPage: currentPage)
        }
    }
    
    private func fetchPage(nextPage: Int) {
        addTask { @MainActor in
            do {
                let page = try await self.repository.fetchFavoriteMovies(page: self.currentPage)
                self.movies = self.movies + page.results
                self.currentPage = page.page ?? 0
                self.maxPages = page.totalPages
                if self.movies.isEmpty {
                    self.state = .empty
                } else {
                    self.state = .content(self.movies)
                }
            } catch {
                log(error.localizedDescription)
                self.state = .error(error)
            }
        }
    }
}
