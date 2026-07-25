//
//  AuthRepository.swift
//  Pixar Fun
//

import Foundation

protocol AuthRepository {

    var isLoggedIn: Bool { get }

    func currentAccountId() -> Int?

    func login() async throws

    func logout()
}
