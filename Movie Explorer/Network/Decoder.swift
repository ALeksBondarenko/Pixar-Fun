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

            guard !dateString.isEmpty, let date = self.dateFormatter.date(from: dateString) else {
                throw DecodingError.valueNotFound(Date.self,.init(codingPath: decoder.codingPath, debugDescription: "Missing or empty date string"))
            }
            
            return date
        })
    }

    func decode<T: Decodable>(_ data: Data) throws -> T {
        try decoder.decode(T.self, from: data)
    }
}
