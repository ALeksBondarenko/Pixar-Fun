//
//  PersonState.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 27.12.2025.
//

import Foundation

enum PersonState {
    case loading
    case content(Person,[PersonImage],[Movie], Error?)
    case error(_ error: Error)
}
