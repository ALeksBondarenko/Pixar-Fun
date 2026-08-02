//
//  LanguageExpression.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 07.01.2026.
//

import Foundation

func iso3166LanguageCode(_ locale: Locale) -> String {
    locale.identifier.replacingOccurrences(of: "_", with: "-")
}
