//
//  MovieExplorerApp.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 24.01.2026.
//

import SwiftUI
import SwiftData
import Swinject
import SwinjectAutoregistration

@main
struct MovieExplorerApp: App {

    var body: some Scene {
        WindowGroup {
            CoordinatorView()
        }
    }
}
