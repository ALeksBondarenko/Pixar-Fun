//
//  FavotireMoviesView.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 30.12.2025.
//

import SwiftUI

struct FavotireMoviesScreen: View {
    
    @StateObject var viewModel: FavotireMoviesViewModel
    @EnvironmentObject var coordinator: Coordinator
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .idle,.loading:
                FullScreenProgressView()
            case .empty:
                EmptyMoviesView()
            case .content(let movies):
                FavoriteMovies(
                    movies: movies,
                    refresh: viewModel.refreshFavotireMovies,
                    loadNextPage: viewModel.fetchMoreFavotireMovies
                )
            case .error(let error):
                ErrorView(error: error, onRetry: viewModel.reloadLastPage, onCancel: coordinator.pop)
            }
        }.onAppear {
            viewModel.fetchFavotireMovies()
        }
        .onDisappear {
            viewModel.cancelAllTasks()
        }
    }
    
    @ViewBuilder
    func EmptyMoviesView() -> some View {
        ZStack(alignment: .center) {
            Text("emptyFavorites")
                .font(.title)
        }
    }
    
    @ViewBuilder
    func FavoriteMovies(
        movies: [Movie],
        refresh: @escaping @Sendable () -> Void,
        loadNextPage: @escaping @Sendable () -> Void
    ) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: [GridItem(.flexible()),GridItem(.flexible())], spacing: 12) {
                ForEach(movies, id: \.id) { movie in
                    PosterView(movie: movie)
                        .onAppear {
                            if movie == movies.last {
                                loadNextPage()
                            }
                        }
                        .onTapGesture {
                            coordinator.route(destination: .details(movie))
                        }
                }
            }
            .padding(.horizontal)
        }.refreshable {
            refresh()
        }
    }
}

#Preview {
    FavotireMoviesScreen(viewModel: FavotireMoviesViewModel(repository: FavoriteRepositoryImpl(
            service: FavoriteService(
                networkClient: NetworkClient(connectionErrorMapper: ConnectionErrorMapper())
            )
        )))
        .environmentObject(Coordinator())
}
