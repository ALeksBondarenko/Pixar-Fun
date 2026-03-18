//
//  SearchState.swift
//  Pixar Fun
//
//  Created by Александр Бондаренко on 25.01.2026.
//

import Foundation

enum SearchState {
    case idle
    case searching
    case empty
    case found([Movie])
    case error(Error)
}
