//
//  NetworkErrorMapper.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 18.01.2026.
//

import Foundation

class ConnectionErrorMapper {
    
    func map(_ error: URLError) -> ConnectionError {
        switch error.code {
        case .notConnectedToInternet:
            return .noInternet
            
        case .timedOut:
            return .timeout
            
        case .networkConnectionLost:
            return .connectionLost
            
        case .cannotFindHost, .cannotConnectToHost:
            return .cannotConnectToHost
            
        case .dataNotAllowed:
            return .networkRestricted
            
        default:
            return .unknown
        }
    }
}
