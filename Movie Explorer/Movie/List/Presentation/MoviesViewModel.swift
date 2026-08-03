//
//  File.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 06.12.2025.
//

import Foundation
import Combine

class MoviesViewModel: ViewModel {
    
    private let repository: MoviesRepository
    @Published private(set) var state: MoviesState = .idle
    
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
        state = .loading
        fetchPage(nextPage: 1)
    }
    
    func fetchMoreMovies() {
        guard currentPage < maxPages else { return }
        guard case .content(let movies, _) = state else { return }
        fetchPage(movies: movies, nextPage: currentPage + 1)
    }
    
    func clearError() {
        if case .content(let movies, _) = self.state {
            self.state = .content(movies, nil)
        }
    }
    
    private func fetchPage(movies: [Movie] = [], nextPage: Int) {
        cancelAllTasks()
        addTask { @MainActor in
            do {
                let page = try await self.repository.fetchMovies(page: nextPage)
                self.currentPage = page.page ?? 0
                self.maxPages = page.totalPages
                self.state = .content(movies + page.results, nil)
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
