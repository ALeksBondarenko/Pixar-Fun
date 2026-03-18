//
//  FavoriteRepository.swift
//  Pixar Fun
//
//  Created by Александр Бондаренко on 25.01.2026.
//

import Foundation

protocol FavoriteRepository {
    
    func fetchFavoriteMovies(page: Int) async throws -> Page
}
