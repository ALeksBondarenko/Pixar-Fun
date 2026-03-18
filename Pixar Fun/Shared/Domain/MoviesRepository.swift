//
//  PixarRepository.swift
//  Pixar Fun
//
//  Created by Александр Бондаренко on 24.01.2026.
//

import Foundation

protocol MoviesRepository {
    
    func fetchMovies(page: Int) async throws -> Page
    
    func fetchMovies(page: Int, genre: Genres) async throws -> Page
}
