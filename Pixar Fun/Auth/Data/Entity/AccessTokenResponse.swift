//
//  AccessTokenResponse.swift
//  Pixar Fun
//

import Foundation

struct AccessTokenRequest: Encodable {
    let requestToken: String

    enum CodingKeys: String, CodingKey {
        case requestToken = "request_token"
    }
}

struct AccessTokenResponse: Decodable {
    let success: Bool
    let accessToken: String

    enum CodingKeys: String, CodingKey {
        case success
        case accessToken = "access_token"
    }
}
