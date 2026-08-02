//
//  Logger.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 04.02.2026.
//

import Foundation

private let APP_NAME = "MOVIE EXPLORER"

func log(
    _ message: String,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    #if DEBUG
    print("\(APP_NAME): [\(file):\(line)] \(function) — \(message)")
    #endif
}

func logRequest(httpMethod: HttpMethod, request: URLRequest) {
    #if DEBUG
    print("--------------------------------------------------------------------------------")
    print("\(APP_NAME): Request: \(httpMethod) \(request)")
    print("--------------------------------------------------------------------------------")
    #endif
}

func logResponse(responce: URLResponse) {
    #if DEBUG
    print("--------------------------------------------------------------------------------")
    print("\(APP_NAME): Response: \(responce)")
    print("--------------------------------------------------------------------------------")
    #endif
}

func logData<T>(data: T) {
    #if DEBUG
    print("--------------------------------------------------------------------------------")
    print("\(APP_NAME): Response data: \(data)")
    print("--------------------------------------------------------------------------------")
    #endif
}
