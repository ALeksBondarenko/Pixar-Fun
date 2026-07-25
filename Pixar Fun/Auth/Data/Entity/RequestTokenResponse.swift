//
//  RequestTokenResponse.swift
//  Pixar Fun
//

import Foundation

struct RequestTokenRequest: Encodable {
    let redirectTo: String

    enum CodingKeys: String, CodingKey {
        case redirectTo = "redirect_to"
    }
}

struct RequestTokenResponse: Decodable {
    let success: Bool
    let requestToken: String

    enum CodingKeys: String, CodingKey {
        case success
        case requestToken = "request_token"
    }
}
