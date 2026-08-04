//
//  MainScreen.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 29.12.2025.
//

import SwiftUI

struct MoviesScreen: View {

    @StateObject var viewModel: MoviesViewModel
    @EnvironmentObject var coordinator: Coordinator

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle,.loading:
                FullScreenProgressView()
            case .content(let movies, let error):
                MoviesView(
                    movies: movies,
                    refresh: viewModel.refreshMovies,
                    loadNextPage: viewModel.fetchMoreMovies
                ).alerError(
                    error: error,
                    onRetry: viewModel.reloadLastPage,
                    onCancel: viewModel.clearError
                )
            }
        }.onAppear {
            viewModel.fetchMovies()
        }
        .onDisappear {
            viewModel.cancelAllTasks()
        }
    }
    
    @ViewBuilder
    func MoviesView(
        movies: [Movie],
        refresh: @escaping @Sendable () -> Void,
        loadNextPage: @escaping @Sendable () -> Void
    ) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: [GridItem(.flexible()),GridItem(.flexible())]) {
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
    MoviesScreen(viewModel: MoviesViewModel(
        repository: MoviesRepositoryImpl(
            service: MoviesService(
                networkClient: NetworkClient(
                        connectionErrorMapper: ConnectionErrorMapper(),
                        sessionTokenProvider: DefaultSessionTokenProvider(sessionStore: KeychainSessionStore()),
                        urlSession: .shared
                    )
            )
        )
    ))
    .environmentObject(Coordinator())
    .preferredColorScheme(ColorScheme.dark)
}


#Preview {
    MoviesScreen(viewModel: MoviesViewModel(
        repository: MoviesRepositoryImpl(
            service: MoviesService(
                networkClient: NetworkClient(
                        connectionErrorMapper: ConnectionErrorMapper(),
                        sessionTokenProvider: DefaultSessionTokenProvider(sessionStore: KeychainSessionStore()),
                        urlSession: .shared
                    )
            )
        )
    ))
    .environmentObject(Coordinator())
}
