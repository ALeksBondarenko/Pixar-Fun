//
//  FavotireMoviesView.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 30.12.2025.
//

import SwiftUI
import Swinject

struct WatchListScreen: View {
    
    @StateObject var viewModel: WatchListViewModel
    @EnvironmentObject var coordinator: Coordinator
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .idle,.loading:
                FullScreenProgressView()
            case .empty:
                EmptyMoviesView()
            case .content(let movies):
                WatchListMovies(
                    movies: movies,
                    refresh: viewModel.refreshMovies,
                    loadNextPage: viewModel.fetchMoreMovies
                )
            case .error(let error):
                ErrorView(error: error, onRetry: viewModel.reloadLastPage, onCancel: coordinator.pop)
            case .unauthenticated:
                LoginPromptView(login: viewModel.login)
            }
        }.onAppear {
            viewModel.fetchMovies()
        }
        .onDisappear {
            viewModel.cancelAllTasks()
        }
    }

    @ViewBuilder
    func EmptyMoviesView() -> some View {
        ZStack(alignment: .center) {
            Text("emptyWatchList")
                .font(.body)
        }
    }

    @ViewBuilder
    func LoginPromptView(login: @escaping () -> Void) -> some View {
        VStack(spacing: 16) {
            Text("loginPromptMessage")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                login()
            } label: {
                Text("loginPromptButton")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color("PrimaryButtonColor"))
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    func WatchListMovies(
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
    WatchListScreen(viewModel: DIContainer.shared.container.resolve(WatchListViewModel.self)!)
        .environmentObject(Coordinator())
}
