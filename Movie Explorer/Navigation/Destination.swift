//
//  Destination.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 10.02.2026.
//


import SwiftUI
import Combine

enum Destination: Hashable {
    case details(Movie)
    case characterInfo(Cast)
    case genre(Genres)
}
