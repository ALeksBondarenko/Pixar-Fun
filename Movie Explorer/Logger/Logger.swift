//
//  Logger.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 04.02.2026.
//

import Foundation

private let APP_NAME = "MOVIE EXPLORER"

/// Header names never printed to the log, regardless of direction (request or response).
private let sensitiveHeaderKeys: Set<String> = ["etag", "if-none-match"]

func log(
    _ error: Error,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    #if DEBUG
    print("\(APP_NAME): [\(file):\(line)] \(function) — \(error)")
    #endif
}

func logRequest(httpMethod: HttpMethod, request: URLRequest) {
    #if DEBUG
    print("--------------------------------------------------------------------------------")
    print("\(APP_NAME): Request: \(httpMethod.name) \(request.url?.absoluteString ?? httpMethod.path)")
    print("\(APP_NAME): Headers: \(sanitizedHeaders(request.allHTTPHeaderFields))")
    print("--------------------------------------------------------------------------------")
    #endif
}

func logResponse(_ response: URLResponse) {
    #if DEBUG
    print("--------------------------------------------------------------------------------")
    if let httpResponse = response as? HTTPURLResponse {
        print("\(APP_NAME): Response: \(httpResponse.statusCode) \(httpResponse.url?.absoluteString ?? "")")
        print("\(APP_NAME): Headers: \(sanitizedHeaders(httpResponse.allHeaderFields))")
    } else {
        print("\(APP_NAME): Response: \(response.url?.absoluteString ?? "")")
    }
    print("--------------------------------------------------------------------------------")
    #endif
}

/// Logs the response body exactly as received over the wire, before any decoding is attempted —
/// so it stays useful even when decoding into a DTO fails or the status code isn't 2xx.
func logBody(_ data: Data) {
    #if DEBUG
    print("--------------------------------------------------------------------------------")
    print("\(APP_NAME): Response body: \(String(data: data, encoding: .utf8) ?? "<\(data.count) bytes, not UTF-8>")")
    print("--------------------------------------------------------------------------------")
    #endif
}

private func sanitizedHeaders(_ headers: [String: String]?) -> [String: String] {
    guard let headers else { return [:] }
    return headers.filter { !sensitiveHeaderKeys.contains($0.key.lowercased()) }
}

private func sanitizedHeaders(_ headers: [AnyHashable: Any]) -> [String: String] {
    var result: [String: String] = [:]
    for (key, value) in headers {
        guard let key = key as? String, !sensitiveHeaderKeys.contains(key.lowercased()) else {
            continue
        }
        result[key] = String(describing: value)
    }
    return result
}
