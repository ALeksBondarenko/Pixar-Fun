//
//  AuthSession.swift
//  Movie Explorer
//

import Foundation

struct AuthSession: Equatable, Codable {
    let accessToken: String
    let accountId: Int
}
