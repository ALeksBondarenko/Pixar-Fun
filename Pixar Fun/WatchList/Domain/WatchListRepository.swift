//
//  FavoriteRepository.swift
//  Pixar Fun
//
//  Created by Александр Бондаренко on 25.01.2026.
//

import Foundation

protocol WatchListRepository {
    
    func fetchMovies(page: Int) async throws -> Page
}
