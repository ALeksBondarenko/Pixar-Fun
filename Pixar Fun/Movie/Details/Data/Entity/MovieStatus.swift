//
//  MovieStatus.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 31.12.2025.
//

import Foundation

struct MovieStatus : Equatable, Codable {
    let id: Int
    let favorite: Bool
    let watchlist: Bool
}
