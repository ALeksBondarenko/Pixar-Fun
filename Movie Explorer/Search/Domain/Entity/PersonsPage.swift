//
//  PersonsPage.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 03.08.2026.
//

import Foundation

// /search/person items are decoded directly as Cast (character stays nil)
// so the existing PersonView and Destination.characterInfo(Cast) can be reused as-is.
struct PersonsPage: Equatable, Codable {
    let page: Int?
    let results: [Cast]
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
    }
}
