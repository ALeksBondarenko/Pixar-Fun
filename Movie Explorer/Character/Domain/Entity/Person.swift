//
//  Person.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 27.12.2025.
//

import Foundation

struct Person: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let profilePath: String?
    let biography: String
    let birthday: Date?
    let deathday: Date?
    let placeOfBirth: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, biography, deathday, birthday
        case profilePath = "profile_path"
        case placeOfBirth = "place_of_birth"
    }
}
