//
//  ResponseParser.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 30.12.2025.
//

import Foundation

class Decoder {
    private let decoder = JSONDecoder()
    private let dateFormatter = DateFormatter()
    
    init() {
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.calendar = .current
        dateFormatter.timeZone = .current
        
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            if dateString.isEmpty {
                return Date()
            } else {
                let date = self.dateFormatter.date(from: dateString)
                if (date != nil) {
                    return date!
                } else {
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
                }
            }
        })
    }
    
    func decode<T: Decodable>(_ data: Data) throws -> T {
        try decoder.decode(T.self, from: data)
    }
}
