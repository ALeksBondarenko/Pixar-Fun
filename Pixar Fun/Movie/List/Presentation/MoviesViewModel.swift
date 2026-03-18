//
//  File.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 06.12.2025.
//

import Foundation
import Combine

class MoviesViewModel: ViewModel {
    
    private let repository: MoviesRepository
    @Published private(set) var state: MoviesState = .idle
    
    private var movies: [Movie] = []
    private var currentPage: Int = 1
    private var maxPages: Int = 1
    
    init(repository: MoviesRepository) {
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
    
    func clearError() {
        if case .content = self.state {
            self.state = .content(self.movies, nil)
        }
    }
    
    private func fetchPage(nextPage: Int) {
        cancelAllTasks()
        addTask { @MainActor in
            do {
                let page = try await self.repository.fetchMovies(page: nextPage)
                self.movies = self.movies + page.results
                self.currentPage = page.page ?? 0
                self.maxPages = page.totalPages
                self.state = .content(self.movies, nil)
            } catch {
                log(error.localizedDescription)
                self.state = .content(self.movies, error)
            }
        }
    }
}
