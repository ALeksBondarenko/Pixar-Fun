//
//  WebAuthPresenter.swift
//  Movie Explorer
//

import AuthenticationServices
import UIKit

protocol WebAuthPresenting {
    func authenticate(url: URL, callbackURLScheme: String) async throws -> URL
}

@MainActor
final class WebAuthPresenter: NSObject, WebAuthPresenting, ASWebAuthenticationPresentationContextProviding {

    // ASWebAuthenticationSession must be kept alive for the whole flow — without this,
    // ARC deallocates it right after `start()` returns (the closure that creates it exits
    // immediately since `start()` is non-blocking), which silently tears down the session
    // before the user finishes in the browser and the completion handler never fires correctly.
    private var activeSession: ASWebAuthenticationSession?

    func authenticate(url: URL, callbackURLScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackURLScheme
            ) { [weak self] callbackURL, error in
                self?.activeSession = nil
                if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
                    continuation.resume(throwing: AuthError.cancelled)
                } else {
                    continuation.resume(throwing: error ?? AuthError.sessionExpired)
                }
            }

            session.presentationContextProvider = self
            activeSession = session
            session.start()
        }
    }

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}
