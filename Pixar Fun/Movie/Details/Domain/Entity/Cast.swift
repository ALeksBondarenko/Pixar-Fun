//
//  Cast.swift
//  Pixar Fun
//
//  Created by Александр Бондаренко on 25.01.2026.
//


import Foundation

struct Cast: Hashable, Codable {
    let id: Int
    let character: String?
    let name: String?
    let profilePath: String?
    
    enum CodingKeys: String, CodingKey {
        case id, character, name, profilePath = "profile_path"
    }
}