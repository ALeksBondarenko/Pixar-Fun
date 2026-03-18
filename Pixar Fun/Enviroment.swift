//
//  Enviroment.swift
//  Pixar Fun
//
//  Created by Александр Бондаренко on 24.01.2026.
//

import Foundation

public enum Enviroment {
    enum Keys {
        static let apiKey = "API_KEY"
        static let accountId = "ACCOUNT_ID"
    }
    
    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("plist file not found")
        }
        return dict
    }()
    
    static let apiKey: String = {
        guard let apiKey = Enviroment.infoDictionary[Keys.apiKey] as? String else {
            fatalError("API key not found in plist file")
        }
        return apiKey
    }()
    
    static let accountId: Int = {
        guard let accountId = Enviroment.infoDictionary[Keys.accountId] as? String else {
            fatalError("Account ID not found in plist file")
        }
        return Int(accountId)!
    }()
}
