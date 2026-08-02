//
//  SessionTokenProvider.swift
//  Movie Explorer
//

import Foundation

protocol SessionTokenProvider {
    func currentBearerToken() -> String
}

final class DefaultSessionTokenProvider: SessionTokenProvider {
    private let sessionStore: SessionStore

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }

    func currentBearerToken() -> String {
        sessionStore.load()?.accessToken ?? Environment.apiKey
    }
}
