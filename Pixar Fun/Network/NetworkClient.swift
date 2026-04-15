//
//  NetworkManager.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 27.12.2025.
//

import Foundation

final class NetworkClient {
    
    private let connectionErrorMapper: ConnectionErrorMapper
    private let decoder = Decoder()
    private let defaultHeaders: [HttpHeader] = [
        .accept(.json),
        .authorization(.bearer(Environment.apiKey))
    ]
    
    init(connectionErrorMapper: ConnectionErrorMapper) {
        self.connectionErrorMapper = connectionErrorMapper
    }
    
    func request<T>(
        _ httpMethod: HttpMethod,
        headers: [HttpHeader] = [],
        queryParams: [Param] = [],
        body: Encodable? = nil,
        timeoutInterval: TimeInterval = 15,
    ) async throws -> T where T: Decodable {
        guard let url = URL(string: httpMethod.path) else {
            throw ConnectionError.noUrl
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.queryItems = queryParams.map{ param in URLQueryItem(name: param.name, value: "\(param.value)")}
        
        guard let url = components?.url else {
            throw ConnectionError.badUrl
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = httpMethod.name
        request.timeoutInterval = timeoutInterval
        
        for header in defaultHeaders {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        for header in headers {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        if let body = body {
            request.httpBody = try? JSONEncoder().encode(body)
        }
        logRequest(httpMethod: httpMethod, request: request)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            logResponse(responce: response)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    let parsedDate: T = try decoder.decode(data)
                    logData(data: parsedDate)
                    return parsedDate
                case 401:
                    throw ApiError.invalidAPIKey
                case 500...503:
                    throw ApiError.serverError
                default:
                    throw ConnectionError.unknown
                }
            }
            
            throw ConnectionError.unknown
        } catch let error as URLError {
            log(error.localizedDescription)
            throw connectionErrorMapper.map(error)
        } catch {
            log(error.localizedDescription)
            throw ConnectionError.unknown
        }
    }
}
