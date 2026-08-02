//
//  File.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 12.04.2026.
//

import Foundation

public enum HttpHeader {
    case accept(MediaType)
    case authorization(AuthorizationType)
    case contentType(MediaType)
    
    var key: String {
        switch self {
        case .authorization: return "Authorization"
        case .contentType: return "Content-Type"
        case .accept: return "Accept"
        }
    }
    
    var value: String {
        switch self {
        case .accept(let mediaType): return mediaType.rawValue
        case .authorization(let authorizationType): return authorizationType.value
        case .contentType(let mediaType): return mediaType.rawValue
        }
    }
}
