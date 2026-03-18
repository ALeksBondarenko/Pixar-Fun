//
//  FavoriteRequest.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 31.12.2025.
//

import Foundation

struct FavoriteRequest: Encodable {
    let mediaType: String = "movie"
    let mediaId: Int
    let favorite: Bool

    enum CodingKeys: String, CodingKey {
        case mediaType = "media_type"
        case mediaId = "media_id"
        case favorite
    }
}
