//
//  AuthRepositoryImplTests.swift
//  Pixar FunTests
//

import Testing
@testable import Pixar_Fun
import Foundation

@MainActor
struct AuthRepositoryImplTests {

    final class MockAuthService: AuthServiceProtocol {
        var requestToken = "request-token"
        var accessToken = "access-token"
        var accountId = 7
        var createAccessTokenError: Error?

        func createRequestToken(redirectTo: String) async throws -> String {
            requestToken
        }

        func createAccessToken(requestToken: String) async throws -> String {
            if let createAccessTokenError {
                throw createAccessTokenError
            }
            return accessToken
        }

        func getAccountId(accessToken: String) async throws -> Int {
            accountId
        }
    }

    final class MockSessionStore: SessionStore {
        var stored: AuthSession?
        var clearCallCount = 0

        func load() -> AuthSession? {
            stored
        }

        func save(_ session: AuthSession) {
            stored = session
        }

        func clear() {
            stored = nil
            clearCallCount += 1
        }
    }

    final class MockWebAuthPresenter: WebAuthPresenting {
        var error: Error?

        func authenticate(url: URL, callbackURLScheme: String) async throws -> URL {
            if let error {
                throw error
            }
            return URL(string: "\(callbackURLScheme)://auth-callback?approved=true")!
        }
    }

    enum MockError: Error {
        case failed
    }

    @Test
    func testLoginSuccessPersistsSession() async {
        let service = MockAuthService()
        let sessionStore = MockSessionStore()
        let webAuthPresenter = MockWebAuthPresenter()
        let repository = AuthRepositoryImpl(service: service, sessionStore: sessionStore, webAuthPresenter: webAuthPresenter)

        #expect(repository.isLoggedIn == false)

        do {
            try await repository.login()
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(repository.isLoggedIn == true)
        #expect(repository.currentAccountId() == service.accountId)
        #expect(sessionStore.stored?.accessToken == service.accessToken)
        #expect(sessionStore.stored?.accountId == service.accountId)
    }

    @Test
    func testLoginCancelledByUserDoesNotPersistSession() async {
        let service = MockAuthService()
        let sessionStore = MockSessionStore()
        let webAuthPresenter = MockWebAuthPresenter()
        webAuthPresenter.error = AuthError.cancelled
        let repository = AuthRepositoryImpl(service: service, sessionStore: sessionStore, webAuthPresenter: webAuthPresenter)

        do {
            try await repository.login()
            Issue.record("Expected login to throw")
        } catch AuthError.cancelled {
            // ok
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }

        #expect(repository.isLoggedIn == false)
        #expect(sessionStore.stored == nil)
    }

    @Test
    func testLoginFailsWhenAccessTokenExchangeFails() async {
        let service = MockAuthService()
        service.createAccessTokenError = MockError.failed
        let sessionStore = MockSessionStore()
        let webAuthPresenter = MockWebAuthPresenter()
        let repository = AuthRepositoryImpl(service: service, sessionStore: sessionStore, webAuthPresenter: webAuthPresenter)

        do {
            try await repository.login()
            Issue.record("Expected login to throw")
        } catch {
            if case MockError.failed = error {
                // ok
            } else {
                Issue.record("Unexpected error type: \(error)")
            }
        }

        #expect(repository.isLoggedIn == false)
        #expect(sessionStore.stored == nil)
    }

    @Test
    func testLogoutClearsSession() async {
        let service = MockAuthService()
        let sessionStore = MockSessionStore()
        sessionStore.stored = AuthSession(accessToken: "token", accountId: 1)
        let webAuthPresenter = MockWebAuthPresenter()
        let repository = AuthRepositoryImpl(service: service, sessionStore: sessionStore, webAuthPresenter: webAuthPresenter)

        #expect(repository.isLoggedIn == true)

        repository.logout()

        #expect(repository.isLoggedIn == false)
        #expect(repository.currentAccountId() == nil)
        #expect(sessionStore.stored == nil)
        #expect(sessionStore.clearCallCount == 1)
    }
}
