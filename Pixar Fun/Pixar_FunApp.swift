//
//  Pixar_FunApp.swift
//  Pixar Fun
//
//  Created by Александр Бондаренко on 24.01.2026.
//

import SwiftUI
import SwiftData
import Swinject
import SwinjectAutoregistration

@main
struct Pixar_FunApp: App {

    var body: some Scene {
        WindowGroup {
            CoordinatorView()
        }
    }
}
