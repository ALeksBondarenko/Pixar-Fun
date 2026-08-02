//
//  AuthRepositoryImpl.swift
//  Movie Explorer
//

import Foundation

final class AuthRepositoryImpl: AuthRepository {

    private let service: AuthServiceProtocol
    private let sessionStore: SessionStore
    private let webAuthPresenter: WebAuthPresenting

    private let callbackURLScheme = "movieexplorer"
    private let redirectTo = "movieexplorer://auth-callback"

    private var session: AuthSession?

    init(
        service: AuthServiceProtocol,
        sessionStore: SessionStore,
        webAuthPresenter: WebAuthPresenting
    ) {
        self.service = service
        self.sessionStore = sessionStore
        self.webAuthPresenter = webAuthPresenter
        self.session = sessionStore.load()
    }

    var isLoggedIn: Bool {
        session != nil
    }

    func currentAccountId() -> Int? {
        session?.accountId
    }

    func login() async throws {
        let requestToken = try await service.createRequestToken(redirectTo: redirectTo)

        var components = URLComponents(string: "https://www.themoviedb.org/auth/access")
        components?.queryItems = [URLQueryItem(name: "request_token", value: requestToken)]

        guard let authURL = components?.url else {
            throw AuthError.sessionExpired
        }

        _ = try await webAuthPresenter.authenticate(url: authURL, callbackURLScheme: callbackURLScheme)

        let accessToken = try await service.createAccessToken(requestToken: requestToken)
        let accountId = try await service.getAccountId(accessToken: accessToken)

        let newSession = AuthSession(accessToken: accessToken, accountId: accountId)
        sessionStore.save(newSession)
        session = newSession
    }

    func logout() {
        sessionStore.clear()
        session = nil
    }
}
