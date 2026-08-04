//
//  GenreByMoviesViewModel.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 07.03.2026.
//

import Foundation
import Combine

final class GenreByMoviesViewModel: ViewModel {
    private let repository: MoviesRepository
    private let genre: Genres
    
    @Published private(set) var state: GenreByMoviesState = .idle
    @Published private(set) var title: String = ""
    
    private var currentPage: Int = 1
    private var maxPages: Int = 1
    
    init(repository: MoviesRepository, genre: Genres) {
        self.repository = repository
        self.genre = genre
        self.title = genre.name.capitalizedFirst
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
                let page = try await self.repository.fetchMovies(page: nextPage, genre: self.genre)
                self.currentPage = page.page ?? nextPage
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

private extension String {
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
