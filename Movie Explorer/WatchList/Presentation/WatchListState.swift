//
//  FavotireMoviesState.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 30.12.2025.
//

import Foundation

enum WatchListState {
    case idle
    case loading
    case empty
    case content([Movie])
    case error(Error)
    case unauthenticated
}
