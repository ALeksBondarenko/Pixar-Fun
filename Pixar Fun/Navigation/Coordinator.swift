//
//  Coordinator.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 30.12.2025.
//

import SwiftUI
import Combine



class Coordinator: ObservableObject {
    
    @Published var path = NavigationPath()
    
    func pop() {
        path.removeLast()
    }
    
    func route(destination: Destination) {
        path.append(destination)
    }
}
