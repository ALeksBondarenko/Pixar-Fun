//
//  Page.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 07.12.2025.
//

import Foundation

struct Page: Equatable, Codable {
    let page: Int?
    let results: [Movie]
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
    }
}
