//
//  NetworkClientTests.swift
//  Movie ExplorerTests
//

import Testing
@testable import Movie_Explorer
import Foundation

/// Records the `Authorization` header per URL. Only installed on a dedicated,
/// per-test `URLSession` (never on `.shared`), so tests stay isolated from each
/// other and from any other network activity in the process.
final class RecordingURLProtocol: URLProtocol {
    static var capturedAuthorizationHeaders: [String: String] = [:]
    static var responseData = "{}".data(using: .utf8)!

    /// NetworkClient always assigns `URLComponents.queryItems` (even an empty array),
    /// which makes Foundation append a trailing "?" to the resulting URL. Normalize
    /// it away so lookups by the caller's original URL still match.
    static func normalizedKey(for url: URL) -> String {
        var value = url.absoluteString
        if value.hasSuffix("?") {
            value.removeLast()
        }
        return value
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        if let url = request.url {
            let key = RecordingURLProtocol.normalizedKey(for: url)
            RecordingURLProtocol.capturedAuthorizationHeaders[key] = request.value(forHTTPHeaderField: "Authorization") ?? ""
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: RecordingURLProtocol.responseData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite(.serialized)
struct NetworkClientTests {

    struct EmptyResponse: Decodable {}

    final class MutableTokenProvider: SessionTokenProvider {
        var token: String

        init(token: String) {
            self.token = token
        }

        func currentBearerToken() -> String {
            token
        }
    }

    private func makeMockURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RecordingURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    @Test
    func testAuthorizationHeaderReflectsCurrentTokenPerRequest() async throws {
        RecordingURLProtocol.capturedAuthorizationHeaders = [:]

        let tokenProvider = MutableTokenProvider(token: "token-1")
        let client = NetworkClient(
            connectionErrorMapper: ConnectionErrorMapper(),
            sessionTokenProvider: tokenProvider,
            urlSession: makeMockURLSession()
        )

        let firstURL = URL(string: "https://example.com/first")!
        let secondURL = URL(string: "https://example.com/second")!

        let _: EmptyResponse = try await client.request(.get(firstURL.absoluteString))

        tokenProvider.token = "token-2"

        let _: EmptyResponse = try await client.request(.get(secondURL.absoluteString))

        #expect(RecordingURLProtocol.capturedAuthorizationHeaders[RecordingURLProtocol.normalizedKey(for: firstURL)] == "Bearer token-1")
        #expect(RecordingURLProtocol.capturedAuthorizationHeaders[RecordingURLProtocol.normalizedKey(for: secondURL)] == "Bearer token-2")
    }

    @Test
    func testCustomAuthorizationHeaderOverridesDefaultToken() async throws {
        RecordingURLProtocol.capturedAuthorizationHeaders = [:]

        let tokenProvider = MutableTokenProvider(token: "default-token")
        let client = NetworkClient(
            connectionErrorMapper: ConnectionErrorMapper(),
            sessionTokenProvider: tokenProvider,
            urlSession: makeMockURLSession()
        )

        let overrideURL = URL(string: "https://example.com/override")!

        let _: EmptyResponse = try await client.request(
            .get(overrideURL.absoluteString),
            headers: [.authorization(.bearer("override-token"))]
        )

        #expect(RecordingURLProtocol.capturedAuthorizationHeaders[RecordingURLProtocol.normalizedKey(for: overrideURL)] == "Bearer override-token")
    }
}
