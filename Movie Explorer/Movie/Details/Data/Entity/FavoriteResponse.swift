//
//  FavoriteResponse.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 31.12.2025.
//

import Foundation

struct FavoriteResponse: Codable {
    let success: Bool
    let statusCode: Int
    let statusMessage: String

    enum CodingKeys: String, CodingKey {
        case success
        case statusCode = "status_code"
        case statusMessage = "status_message"
    }
}
