//
//  Enviroment.swift
//  Pixar Fun
//
//  Created by Александр Бондаренко on 24.01.2026.
//

import Foundation

public enum Environment {
    enum Keys {
        static let apiKey = "API_KEY"
    }

    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("plist file not found")
        }
        return dict
    }()

    static let apiKey: String = {
        guard let apiKey = Environment.infoDictionary[Keys.apiKey] as? String else {
            fatalError("API key not found in plist file")
        }
        return apiKey
    }()
}
