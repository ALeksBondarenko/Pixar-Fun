//
//  HttpMethod.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 12.04.2026.
//


import Foundation

enum HttpMethod {
    case get(String)
    case post(String)
    
    var name: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        }
    }
    
    var path: String {
        switch self {
        case .get(let path): return path
        case .post(let path): return path   
        }
    }
}
