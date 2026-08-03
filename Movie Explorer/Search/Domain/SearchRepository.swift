//
//  SearchRepository.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 03.08.2026.
//

import Foundation

protocol SearchRepository {

    func searchMovies(query: String, page: Int) async throws -> Page

    func searchPersons(query: String, page: Int) async throws -> PersonsPage

    func searchKeywords(query: String, page: Int) async throws -> KeywordsPage
}
