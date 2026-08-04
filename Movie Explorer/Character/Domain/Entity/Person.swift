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

    init(
        id: Int,
        name: String,
        profilePath: String?,
        biography: String,
        birthday: Date?,
        deathday: Date?,
        placeOfBirth: String?
    ) {
        self.id = id
        self.name = name
        self.profilePath = profilePath
        self.biography = biography
        self.birthday = birthday
        self.deathday = deathday
        self.placeOfBirth = placeOfBirth
    }

    // TMDB sometimes sends an empty string for birthday/deathday (e.g. still alive, or
    // unknown). The shared Decoder throws for that rather than guessing a date, so both
    // are decoded leniently here via `try?` instead of relying on decodeIfPresent, which
    // would let that throw fail the whole Person instead of just these fields.
    init(from decoder: Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
        biography = try container.decode(String.self, forKey: .biography)
        placeOfBirth = try container.decodeIfPresent(String.self, forKey: .placeOfBirth)
        birthday = try? container.decode(Date.self, forKey: .birthday)
        deathday = try? container.decode(Date.self, forKey: .deathday)
    }
}
