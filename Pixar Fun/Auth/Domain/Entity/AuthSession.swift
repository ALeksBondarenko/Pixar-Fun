//
//  AuthSession.swift
//  Pixar Fun
//

import Foundation

struct AuthSession: Equatable, Codable {
    let accessToken: String
    let accountId: Int
}
