//
//  State.swift
//  Pixar Fun
//
//  Created by Александр Бондаренко on 07.03.2026.
//

import Foundation

enum GenreByMoviesState {
    case idle
    case loading
    case content([Movie], Error?)
}
