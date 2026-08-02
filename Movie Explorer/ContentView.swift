//
//  ContentView.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 06.12.2025.
//

import SwiftUI
import SwiftData
import Swinject

struct ContentView: View {
    @EnvironmentObject var coordinator: Coordinator
    
    var body: some View {
        TabView {
            Tab("movies_tab_name", systemImage: "movieclapper") {
                MoviesScreen(viewModel: DIContainer.shared.container.resolve(MoviesViewModel.self)!)
                    .environmentObject(coordinator)
            }
            
            Tab("watchlist_tab_name", systemImage: "bookmark") {
                WatchListScreen(viewModel: DIContainer.shared.container.resolve(WatchListViewModel.self)!)
                    .environmentObject(coordinator)
            }
            
            Tab("favorite_tab_name", systemImage: "heart") {
                FavotireMoviesScreen(viewModel: DIContainer.shared.container.resolve(FavotireMoviesViewModel.self)!)
                    .environmentObject(coordinator)
            }
            
            Tab("search_tab_name", systemImage: "magnifyingglass") {
                SearchScreen(viewModel: DIContainer.shared.container.resolve(SearchViewModel.self)!)
                .environmentObject(coordinator)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(Coordinator())
}
