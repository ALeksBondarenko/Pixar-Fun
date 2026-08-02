//
//  SwiftUIView.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 18.01.2026.
//

import SwiftUI

struct ErrorView: View {
    let error: Error
    let onRetry: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Group {
            if error.isRetryable {
                RetryDialog(message: error.toString(), onRetry: onRetry, onCancel: onCancel)
            } else {
                OkDialog(message: error.toString(), onDissmiss: onCancel)
            }
        }
    }
    
    @ViewBuilder
    private func OkDialog(message: String, onDissmiss: @escaping () -> Void) -> some View {
        VStack {
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding()
            
            Button {
                onDissmiss()
            } label: {
                Text("OK")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("ButtonColor"), lineWidth: 2)
                    )
            }
            .padding(.bottom)
        }
        .padding()
        .background(Color("AlertBackground"))
        .cornerRadius(10)
        .shadow(radius: 10)
    }
    
    @ViewBuilder
    private func RetryDialog(
        message: String,
        onRetry: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        VStack {
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding()
            
            HStack {
                Button {
                    onCancel()
                } label: {
                    Text("cancelButton")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("PrimaryButtonColor"), lineWidth: 2)
                        )
                }
                .padding(.horizontal)
                
                Button {
                    onRetry()
                } label: {
                    Text("repeatButton")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color("PrimaryButtonColor"))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
            }
        }
        .padding()
        .background(Color("AlertBackground"))
        .cornerRadius(10)
        .shadow(radius: 10)
    }
}

extension View {
    
    func alerError(
        error: Error?,
        onRetry: @escaping () -> Void,
        onCancel: @escaping () -> Void,
    ) -> some View {
        self.alert(
            "error",
            isPresented: Binding<Bool>(
                get: { error != nil },
                set: { _ in },
            )
        )
        {
            if let wrappedError = error, wrappedError.isRetryable {
                Button("cancelButton", role: .cancel) {
                    onCancel()
                }
                
                Button("repeatButton", role: .confirm) {
                    onRetry()
                }
            } else {
                Button("OK", role: .confirm) {
                    onCancel()
                }
            }
            
        } message: {
            if let error = error {
                Text(error.toString())
            } else {
                Text("unknown")
            }
        }
    }
}

private extension Error {
    
    func toString() -> String {
        switch self {
        case let connectionError as ConnectionError: mapConnestionErrorToString(connectionError)
        case let apiError as ApiError: mapApiErrorToString(apiError)
        case is AuthError: String(localized: "notAuthenticated")
        default: "unknown"
        }
    }
    
    private func mapConnestionErrorToString(_ error: ConnectionError) -> String {
        return switch error {
        case .noInternet: String(localized: "noInternet")
        case .timeout: String(localized: "timeout")
        case .connectionLost: String(localized: "connectionLost")
        case .cannotConnectToHost: String(localized: "cannotConnectToHost")
        case .networkRestricted: String(localized: "networkRestricted")
        default: String(localized: "unknown")
        }
    }

    private func mapApiErrorToString(_ error: ApiError) -> String {
        return switch error {
        case .invalidAPIKey: String(localized: "invalidAPIKey")
        case .authenticationFailed: String(localized: "authenticationFailed")
        case .invalidParameters: String(localized: "invalidParameters")
        case .notFound: String(localized: "notFound")
        case .rateLimited: String(localized: "rateLimited")
        case .serviceOffline: String(localized: "serviceOffline")
        case .internalServerError: String(localized: "internalServerError")
        default: String(localized: "unknown")
        }
    }
}


fileprivate extension Error {
    
    var isRetryable: Bool {
        switch self {
        case is ConnectionError: return true
        case is AuthError: return true
        default: return false
        }
    }
}

#Preview {
    ErrorView(error: ConnectionError.noInternet, onRetry: {}, onCancel: {})
}

#Preview() {
    ErrorView(error: ConnectionError.noInternet, onRetry: {}, onCancel: {})
        .preferredColorScheme(ColorScheme.dark)
}
