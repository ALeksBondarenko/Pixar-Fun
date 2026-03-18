//
//  SearchScreen.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 03.01.2026.
//

import SwiftUI

struct SearchScreen: View {
    @StateObject var viewModel: SearchViewModel
    @EnvironmentObject var coordinator: Coordinator
    @State var searchText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("searchMovies", text: $searchText)
                    .onChange(of: searchText) { query in
                        viewModel.search(query)
                    }
                    .focused($isFocused)
            }
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("Border"), lineWidth: 2)
                
            }
            .padding(.horizontal)
            .onTapGesture {
                isFocused = true
            }
            
            switch viewModel.state {
            case .idle:
                ContentUnavailableView("startTyping", systemImage: "magnifyingglass")
            case .searching:
                FullScreenProgressView()
            case .found(let movies):
                FoundMoviesView(movies: movies)
            case .empty:
                ContentUnavailableView("noResults", systemImage: "film")
            case .error(let error):
                ErrorView(error: error, onRetry: viewModel.loadAllMovies, onCancel: coordinator.pop)
            }
        }.onAppear {
            viewModel.loadAllMovies()
        }.onDisappear {
            viewModel.cancelAllTasks()
        }
    }
    
    @ViewBuilder
    func FoundMoviesView(movies: [Movie]) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: [GridItem(.flexible()),GridItem(.flexible())]) {
                ForEach(movies, id: \.id) { movie in
                    PosterView(movie: movie)
                        .onTapGesture {
                            coordinator.route(destination: .details(movie))
                        }
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    SearchScreen(viewModel: SearchViewModel(
        repository: MoviesRepositoryImpl(
            service: MoviesService(
                networkClient: NetworkClient(connectionErrorMapper: ConnectionErrorMapper())
            )
        )
    ))
    .environmentObject(Coordinator())
}
