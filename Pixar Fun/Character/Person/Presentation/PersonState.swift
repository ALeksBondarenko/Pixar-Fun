//
//  PersonState.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 27.12.2025.
//

import Foundation

enum PersonState {
    case loading
    case content(Person,[PersonImage],[Movie])
    case error(_ error: Error)
}
