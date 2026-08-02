//
//  SearchViewModel.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 03.01.2026.
//

import Foundation
import Combine
import SwiftUI

class SearchViewModel: ViewModel {

    private let repository: MoviesRepository
    private var allMovies: [Movie] = []
    
    @Published private(set) var state: SearchState = .idle
    
    init(repository: MoviesRepository) {
        self.repository = repository
    }
    
    func loadAllMovies() {
        addTask { @MainActor in
            do {
                var page = try await self.repository.fetchMovies(page: 1)
                self.allMovies = page.results
                while page.totalPages > page.page! {
                    let nextPage = try await self.repository.fetchMovies(page: page.page! + 1)
                    self.allMovies.append(contentsOf: nextPage.results)
                    page = nextPage
                }
            } catch {
                log(error.localizedDescription)
                self.state = .error(error)
            }
        }
    }
    
    func search(_ query: String) {
        guard query.count > 2 else {
            state = .idle
            return
        }
        state = .searching
        
        let filteredMovies = allMovies.filter { movie in
            movie.title.lowercased().contains(query.lowercased())
        }
        
        if filteredMovies.isEmpty {
            state = .empty
        } else {
            state = .found(filteredMovies)
        }
    }
    
    func clearError() {
        if case .error = self.state {
            self.state = .idle
        }
    }
}
