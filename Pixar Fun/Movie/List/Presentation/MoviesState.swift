//
//  MainState.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 06.12.2025.
//

import Foundation

enum MoviesState {
    case idle
    case loading
    case content([Movie], Error?)
}
