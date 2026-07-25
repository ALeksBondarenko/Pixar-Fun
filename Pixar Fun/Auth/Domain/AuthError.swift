//
//  AuthError.swift
//  Pixar Fun
//

import Foundation

enum AuthError: Error {
    case notAuthenticated
    case cancelled
    case sessionExpired
}
