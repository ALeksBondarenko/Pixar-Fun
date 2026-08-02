//
//  FavoriteRequest.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 31.12.2025.
//

import Foundation

struct WachListRequest: Encodable {
    let mediaType: String = "movie"
    let mediaId: Int
    let watchlist: Bool

    enum CodingKeys: String, CodingKey {
        case mediaType = "media_type"
        case mediaId = "media_id"
        case watchlist
    }
}
