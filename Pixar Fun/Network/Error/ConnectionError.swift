//
//  File.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 18.01.2026.
//

import Foundation

enum ConnectionError: Error {
    case noUrl
    case badUrl
    case noInternet
    case timeout
    case connectionLost
    case cannotConnectToHost
    case networkRestricted
    case unknown
}
