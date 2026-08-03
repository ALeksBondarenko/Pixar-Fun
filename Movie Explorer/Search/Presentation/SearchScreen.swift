//
//  SearchScreen.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 03.01.2026.
//

import SwiftUI

struct SearchScreen: View {
    @StateObject var viewModel: SearchViewModel
    @EnvironmentObject var coordinator: Coordinator
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchField

            switch viewModel.state {
            case .idle:
                ContentUnavailableView("startTyping", systemImage: "magnifyingglass")
            case .searching:
                FullScreenProgressView()
            case .content(let content):
                if content.isEmpty && !hasAnyError(content) {
                    ContentUnavailableView("noResults", systemImage: "film")
                } else {
                    resultsView(content)
                }
            case .error(let error):
                ErrorView(error: error, onRetry: viewModel.retry, onCancel: coordinator.pop)
            }
        }
        .onDisappear {
            viewModel.cancelAllTasks()
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("searchMovies", text: $viewModel.query)
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
    }

    private func hasAnyError(_ content: SearchContent) -> Bool {
        content.movies.initialError != nil
            || content.persons.initialError != nil
            || content.suggestions.initialError != nil
    }

    @ViewBuilder
    private func resultsView(_ content: SearchContent) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 24) {
                HorizontalSection(
                    title: "suggestions",
                    section: content.suggestions,
                    loadMore: viewModel.loadMoreSuggestions,
                    retry: viewModel.retrySuggestions
                ) { keyword in
                    SuggestionChip(keyword)
                        .onTapGesture {
                            isFocused = false
                            viewModel.selectSuggestion(keyword)
                        }
                }

                HorizontalSection(
                    title: "movies",
                    section: content.movies,
                    loadMore: viewModel.loadMoreMovies,
                    retry: viewModel.retryMovies
                ) { movie in
                    PosterView(movie: movie)
                        .onTapGesture {
                            coordinator.route(destination: .details(movie))
                        }
                }

                HorizontalSection(
                    title: "people",
                    section: content.persons,
                    loadMore: viewModel.loadMorePersons,
                    retry: viewModel.retryPersons
                ) { cast in
                    PersonView(cast: cast)
                        .onTapGesture {
                            coordinator.route(destination: .characterInfo(cast))
                        }
                }
            }
            .padding(.vertical)
        }
    }

    @ViewBuilder
    private func HorizontalSection<Item: Identifiable, ItemContent: View>(
        title: LocalizedStringKey,
        section: SearchSectionState<Item>,
        loadMore: @escaping () -> Void,
        retry: @escaping () -> Void,
        @ViewBuilder itemView: @escaping (Item) -> ItemContent
    ) -> some View {
        if !section.items.isEmpty || section.initialError != nil {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title3.bold())
                    .padding(.horizontal)
                    .accessibilityAddTraits(.isHeader)

                if section.items.isEmpty, section.initialError != nil {
                    Button(action: retry) {
                        Label("loadFailed", systemImage: "arrow.clockwise")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            ForEach(section.items) { item in
                                itemView(item)
                                    .onAppear {
                                        if item.id == section.items.last?.id {
                                            loadMore()
                                        }
                                    }
                            }

                            if section.isLoadingNextPage {
                                ProgressView()
                                    .frame(width: 40)
                            } else if section.pageError != nil {
                                Button(action: loadMore) {
                                    Image(systemName: "arrow.clockwise.circle")
                                        .font(.title2)
                                }
                                .accessibilityLabel(Text("repeatButton"))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func SuggestionChip(_ keyword: Keyword) -> some View {
        Text(keyword.name)
            .font(.subheadline)
            .lineLimit(1)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(Color("Background"))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color("Border"), lineWidth: 1)
            )
            .contentShape(Capsule())
            .accessibilityLabel(Text(keyword.name))
            .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    SearchScreen(viewModel: SearchViewModel(
        repository: SearchRepositoryImpl(
            service: SearchService(
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
