//
//  KeychainSessionStoreTests.swift
//  Movie ExplorerTests
//

import Testing
@testable import Movie_Explorer
import Foundation

struct KeychainSessionStoreTests {

    private func makeStore() -> KeychainSessionStore {
        KeychainSessionStore(service: "com.aleksbondarenko.movieexplorer.tests.\(UUID().uuidString)", account: "session")
    }

    @Test
    func testSaveAndLoadRoundTrips() {
        let store = makeStore()
        defer { store.clear() }

        let session = AuthSession(accessToken: "token-123", accountId: 42)
        store.save(session)

        #expect(store.load() == session)
    }

    @Test
    func testLoadReturnsNilWhenNothingStored() {
        let store = makeStore()
        defer { store.clear() }

        #expect(store.load() == nil)
    }

    @Test
    func testClearRemovesStoredSession() {
        let store = makeStore()
        defer { store.clear() }

        store.save(AuthSession(accessToken: "token-456", accountId: 1))
        store.clear()

        #expect(store.load() == nil)
    }

    @Test
    func testSaveOverwritesPreviousSession() {
        let store = makeStore()
        defer { store.clear() }

        store.save(AuthSession(accessToken: "first", accountId: 1))
        store.save(AuthSession(accessToken: "second", accountId: 2))

        #expect(store.load() == AuthSession(accessToken: "second", accountId: 2))
    }
}
