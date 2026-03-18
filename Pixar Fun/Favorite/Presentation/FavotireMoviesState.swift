//
//  FavotireMoviesState.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 30.12.2025.
//

import Foundation

enum FavotireMoviesState {
    case idle
    case loading
    case empty
    case content([Movie])
    case error(Error)
}
