//
//  AuthError.swift
//  Movie Explorer
//

import Foundation

enum AuthError: Error {
    case notAuthenticated
    case cancelled
    case sessionExpired
}
