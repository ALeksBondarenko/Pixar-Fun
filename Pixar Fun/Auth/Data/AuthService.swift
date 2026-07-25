//
//  AuthService.swift
//  Pixar Fun
//

import Foundation

protocol AuthServiceProtocol {

    func createRequestToken(redirectTo: String) async throws -> String

    func createAccessToken(requestToken: String) async throws -> String

    func getAccountId(accessToken: String) async throws -> Int
}

class AuthService: AuthServiceProtocol {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func createRequestToken(redirectTo: String) async throws -> String {
        let response: RequestTokenResponse = try await networkClient.request(
            .post("https://api.themoviedb.org/4/auth/request_token"),
            queryParams: [Param(name: "redirect_to", value: redirectTo)]
        )
        return response.requestToken
    }

    func createAccessToken(requestToken: String) async throws -> String {
        let response: AccessTokenResponse = try await networkClient.request(
            .post("https://api.themoviedb.org/4/auth/access_token"),
            queryParams: [Param(name: "request_token", value: requestToken)]
        )
        return response.accessToken
    }

    func getAccountId(accessToken: String) async throws -> Int {
        let response: AccountResponse = try await networkClient.request(.get("https://api.themoviedb.org/3/account"))
        return response.id
    }
}
