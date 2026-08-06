//
//  MovieDetailsState.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 29.12.2025.
//
import Foundation
import Combine

enum MovieDetailsState{
    case loading
    case success(MovieDetails,[Frame],[Video],[Cast], favorite: Bool = false, watchLater: Bool = false, [Movie], Error?)
    case failure(Error)
}
