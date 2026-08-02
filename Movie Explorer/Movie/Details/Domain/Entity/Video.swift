//
//  Video.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 25.01.2026.
//


import Foundation

struct Video: Equatable, Codable {
    let key: String
    let site: String
    let type: String
    let official: Bool
}
