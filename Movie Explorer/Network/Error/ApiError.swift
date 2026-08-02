//
//  ApiError.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 18.01.2026.
//

import Foundation

enum ApiError: Error, LocalizedError {
    case invalidAPIKey
    case authenticationFailed
    case invalidParameters
    case notFound
    case rateLimited
    case serviceOffline
    case internalServerError
    case serverError
}
