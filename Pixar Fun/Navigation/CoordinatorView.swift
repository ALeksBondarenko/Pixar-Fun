//
//  CoordinatorView.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 05.01.2026.
//

import SwiftUI
import Swinject

struct CoordinatorView: View {
    @ObservedObject private var coordinator = Coordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ContentView()
                .environmentObject(coordinator)
                .navigationDestination(for: Destination.self, destination: { pageAction in
                    buildView(forPageAction: pageAction)
                })
        }
    }
    
    @ViewBuilder
    func buildView(forPageAction pageAction: Destination) -> some View {
        switch pageAction {
        case .details(let movie):
            MovieDetailsScreen(viewModel: DIContainer.shared.container.resolve(MovieDetailsViewModel.self, argument: movie)!)
                .environmentObject(coordinator)
        case .characterInfo(let cast):
            PersonScreen(viewModel: DIContainer.shared.container.resolve(PersonViewModel.self, argument: cast)!)
                .environmentObject(coordinator)
        case .genre(let genre):
            GenreByMoviesScreen(viewModel: DIContainer.shared.container.resolve(GenreByMoviesViewModel.self, argument: genre)!)
                .environmentObject(coordinator)
        }
    }
}

#Preview {
    CoordinatorView()
}
