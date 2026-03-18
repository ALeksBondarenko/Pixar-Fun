//
//  FavotireMoviesViewModel.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 30.12.2025.
//

import Foundation
import Combine

class WatchListViewModel: ViewModel {
    
    private let repository: WatchListRepository
    @Published private(set) var state: WatchListState = .idle
    
    private var movies: [Movie] = []
    private var currentPage: Int = 1
    private var maxPages: Int = 1
    
    init(repository: WatchListRepository) {
        self.repository = repository
    }
    
    func fetchMovies() {
        if case .idle = state {
            state = .loading
            fetchPage(nextPage: currentPage)
        }
    }
    
    func refreshMovies() {
        movies.removeAll()
        currentPage = 1
        state = .loading
        fetchPage(nextPage: currentPage)
    }
    
    func fetchMoreMovies() {
        if currentPage >= maxPages {
            return
        }
        currentPage = currentPage + 1
        fetchPage(nextPage: currentPage)
    }
    
    func reloadLastPage() {
        if case .error(_) = state {
            fetchPage(nextPage: currentPage)
        }
    }
    
    private func fetchPage(nextPage: Int) {
        addTask { @MainActor in
            do {
                let page = try await self.repository.fetchMovies(page: self.currentPage)
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
