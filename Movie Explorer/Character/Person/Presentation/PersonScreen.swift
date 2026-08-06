//
//  PersonView.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 27.12.2025.
//

import SwiftUI

struct PersonScreen: View {
    
    @StateObject var viewModel: PersonViewModel
    @EnvironmentObject private var coordinator: Coordinator

    @State private var selectedPhotoIndex: Int = 0
    @State private var isShowingPhotoGallery = false

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                FullScreenProgressView()
            case .content(let person, let photos, let movies, let error):
                PersonView(
                    person: person,
                    photos: photos,
                    movies: movies,
                    refresh: viewModel.loadInitMoviePage,
                    loadNextMoviePage: viewModel.loadNextMoviePage,
                )
                .alerError(
                    error: error,
                    onRetry: viewModel.reloadLastPage,
                    onCancel: viewModel.clearError,
                )
            case .error(let error):
                ErrorView(error: error, onRetry: viewModel.loadInitMoviePage, onCancel: coordinator.pop)
            }
        }
        .onAppear {
            viewModel.loadInitMoviePage()
        }
        .onDisappear {
            viewModel.cancelAllTasks()
        }
    }
    
    @ViewBuilder
    func PersonView(
        person: Person,
        photos: [PersonImage],
        movies: [Movie],
        refresh: @escaping @Sendable () -> Void,
        loadNextMoviePage: @escaping @Sendable () -> Void,
    ) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading) {
                Header(person: person)
                    .padding(.horizontal)
                
                Spacer()
                
                if !person.biography.isEmpty {
                    Text("biography")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                    
                    
                    Text(person.biography)
                        .font(.caption)
                        .truncationEffect(lenght: 3, moreText: "more", animation: .smooth(duration: 0.5, extraBounce: 0))
                        .padding(.horizontal)
                }
                
                if !photos.isEmpty {
                    Text("photo")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                        .padding(.top, 12)
                        .padding(.horizontal)
                    
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(photos.enumerated()), id: \.element.filePath) { index, photo in
                                    CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(photo.filePath)")) { image in
                                        image.resizable()
                                    } placeholder: {
                                        ProgressView()
                                    } failure: { _ in
                                        ProgressView()
                                    }
                                    .cornerRadius(16)
                                    .aspectRatio(contentMode: .fit)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedPhotoIndex = index
                                        isShowingPhotoGallery = true
                                    }
                                    .frame(width: 160, height: 240)
                                    .id(index)
                                }
                            }.padding(.horizontal)
                        }
                        .onChange(of: selectedPhotoIndex) { _, newIndex in
                            withAnimation {
                                proxy.scrollTo(newIndex, anchor: .center)
                            }
                        }
                    }
                    .fullScreenCover(isPresented: $isShowingPhotoGallery) {
                        ImageGalleryView(
                            images: photos.map(\.filePath),
                            currentIndex: $selectedPhotoIndex
                        )
                    }
                }
                
                Text("movies")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                    .padding(.top, 12)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(movies, id: \.id) { movie in
                            PosterView(movie: movie)
                                .onAppear {
                                    if movie == movies.last {
                                        loadNextMoviePage()
                                    }
                                }
                                .onTapGesture {
                                    coordinator.route(destination: .details(movie))
                                }
                        }
                    }
                    .padding(.horizontal, 15)
                }
            }
        }.refreshable {
            refresh()
        }
    }
    
    @ViewBuilder
    func Header(person: Person)  -> some View {
        HStack(alignment: .top) {
            AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(person.profilePath ?? "" )")) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 160, height: 240)
            .cornerRadius(16)
            .aspectRatio(contentMode: .fit)
            .padding(.trailing)
            
            VStack(alignment: .leading) {
                Text(person.name)
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let placeOfBirth = person.placeOfBirth {
                    Text(placeOfBirth)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let birthday = person.birthday {
                    Text(birthday, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    PersonScreen(viewModel: PersonViewModel(repository: PersonRepositoryImpl(service: PersonService(networkClient: NetworkClient(
        connectionErrorMapper: ConnectionErrorMapper(),
        sessionTokenProvider: DefaultSessionTokenProvider(sessionStore: KeychainSessionStore()),
        urlSession: .shared
    ))), cast: Cast(id: 16828, character: "Buzz Lightyear (voice)", name: "Chris Evans", profilePath: "/3bOGNsHlrswhyW79uvIHH1V43JI.jpg")))
        .environmentObject(Coordinator())
}
