//
//  SearchState.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 25.01.2026.
//

import Foundation

enum SearchState {
    case idle
    case searching
    case content(SearchContent)
    case error(Error)
}

struct SearchContent {
    let query: String
    var suggestions = SearchSectionState<Keyword>()
    var movies = SearchSectionState<Movie>()
    var persons = SearchSectionState<Cast>()

    var isEmpty: Bool {
        suggestions.items.isEmpty && movies.items.isEmpty && persons.items.isEmpty
    }
}
