//
//  NetworkManager.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 27.12.2025.
//

import Foundation

public typealias Headers = [String:String]
public typealias QueryParameters = [String:Any]

enum HttpMethod: String {
    case GET = "GET"
    case POST = "POST"
}

final class NetworkClient {
    
    private let connectionErrorMapper: ConnectionErrorMapper
    private let decoder = Decoder()
    private let timeoutInterval = 15.0
    private let defaultHeaders = [
        "accept": "application/json",
        "Authorization": "Bearer \(Enviroment.apiKey)"
    ]
    
    init(connectionErrorMapper: ConnectionErrorMapper) {
        self.connectionErrorMapper = connectionErrorMapper
    }
    
    func request<T>(httpMethod: HttpMethod, stringUrl: String, headers: Headers = [:], queryParams: QueryParameters = [:], body: Encodable? = nil) async throws -> T where T: Decodable {
        let url = URL(string: stringUrl)!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.queryItems = [URLQueryItem]()
        for (key, value) in queryParams {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems?.append(queryItem)
        }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = httpMethod.rawValue
        request.timeoutInterval = timeoutInterval
        
        for (key, value) in defaultHeaders {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
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
