//
//  MovieUIView.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 06.12.2025.
//

import SwiftUI

struct MovieDetailsScreen: View {
    
    @StateObject var viewModel: MovieDetailsViewModel
    @EnvironmentObject var coordinator: Coordinator
    
    @State private var selectedImage: Frame?
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                FullScreenProgressView()
            case .success(let movie, let images, let videos, let casts, let favorite, let watchLater):
                MovieDetailsView(movieDetails: movie, images: images, videos: videos, casts: casts, favorite: favorite, watchLater: watchLater)
            case .failure(let error):
                ErrorView(error: error, onRetry: viewModel.requestDetails, onCancel: coordinator.pop)
            }
        }
        .onAppear {
            viewModel.requestDetails()
        }
        .onDisappear {
            viewModel.cancelAllTasks()
        }
    }
    
    @ViewBuilder
    func MovieDetailsView(movieDetails: MovieDetails, images: [Frame], videos:[Video], casts: [Cast], favorite: Bool, watchLater: Bool) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading){
                Header(movieDetails: movieDetails)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack {
                        ForEach(movieDetails.genres, id: \.id) { genre in
                            Text(genre.name)
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.blue)
                                .cornerRadius(18)
                                .onTapGesture {
                                    coordinator.route(destination: .genre(genre))
                                }
                        }
                    }.padding(.horizontal)
                }.padding(.top)
                
                if !movieDetails.overview.isEmpty {
                    Text("overview")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    Text(movieDetails.overview)
                        .font(.body)
                        .padding(.horizontal)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(images, id: \.filePath) { image in
                            ScalableAsyncImageView(string: image.filePath)
                                .frame(width: 340, height: 180)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                
                if (!videos.isEmpty) {
                    Text("trailers")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack {
                            ForEach(videos, id: \.key) { video in
                                VideoView(videoID: video.key)
                                    .frame(width: 340, height: 180)
                                    .cornerRadius(12)
                            }
                        }.padding(.horizontal)
                    }
                }
                
                if (!casts.isEmpty) {
                    Text("cast")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(casts, id: \.name) { cast in
                                VStack {
                                    CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(cast.profilePath ?? "")")) { image in
                                        image.resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Image(systemName: "person.crop.circle")
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                    } failure: { _ in
                                        Image(systemName: "person.crop.circle")
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                    }
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    
                                    Text(cast.character ?? "N/A")
                                        .font(.caption.bold())
                                    
                                    Text(cast.name ?? "N/A")
                                        .font(.caption2)
                                        .foregroundStyle(.gray)
                                }
                                .frame(maxWidth: 120)
                                .onTapGesture {
                                    coordinator.route(destination: .characterInfo(cast))
                                }
                            }
                        }.padding(.horizontal)
                    }
                }
            }
        }
        .frame(maxHeight:.infinity, alignment: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    coordinator.pop()
                } label : {
                    Label("back", systemImage: "chevron.left")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.toggleWatchLater()
                } label : {
                    Label("watchLater", systemImage: watchLater ? "bookmark.fill" : "bookmark")
                        .foregroundColor(watchLater ? .red : .gray)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.toggleFavorites()
                } label : {
                    Label("favorite", systemImage: favorite ? "heart.fill" : "heart")
                        .foregroundColor(favorite ? .red : .gray)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    func Header(movieDetails: MovieDetails)  -> some View {
        ZStack(alignment: .leading) {
            CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/original\(movieDetails.backdropPath)")) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            } failure: { _ in
                ProgressView()
            }
            .aspectRatio(contentMode: .fit)
            .overlay {
                LinearGradient(gradient: Gradient(colors: [Color.clear, Color("Background")]), startPoint: .top, endPoint: .bottom)
            }
            .stretchable()
            
            HStack(alignment: .bottom) {
                AsyncPosterImage(posterPath: movieDetails.posterPath)
                
                VStack(alignment: .leading) {
                    Text(movieDetails.title)
                        .font(.title.bold())
                    
                    if movieDetails.voteAverage > 0 {
                        HStack {
                            Image(systemName: "star.fill").foregroundColor(.yellow)
                            Text("\(movieDetails.voteAverage, specifier: "%.1f")")
                                .font(.caption)
                        }
                    }
                    
                    Text(movieDetails.releaseDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading)
            }
            .padding(.top, 120)
            .padding(.horizontal)
        }
    }
}

fileprivate extension View {
    
    func stretchable() -> some View {
        visualEffect { effect, geometry in
            let frame = geometry.frame(in: .scrollView)
            
            let offset: CGFloat = frame.minY
            let currentLength: CGFloat = geometry.size.height
            
            let positiveOffset = max(0, offset)
            let scale = (currentLength + positiveOffset) / max(currentLength, 0.0001)
            
            return effect.scaleEffect(x: scale, y: scale, anchor: .bottom)
        }
    }
}

#Preview {
    MovieDetailsScreen(viewModel: MovieDetailsViewModel(repository: MovieDetailRepositoryImpl(service: MovieDetailsService(networkClient: NetworkClient(connectionErrorMapper: ConnectionErrorMapper()))), movie: Movie(id: 1022787, title: "Elio", overview: "overview", posterPath: "posterPath", releaseDate: Date())))
        .environmentObject(Coordinator())
        .preferredColorScheme(ColorScheme.dark)
}

#Preview {
    MovieDetailsScreen(viewModel: MovieDetailsViewModel(repository: MovieDetailRepositoryImpl(service: MovieDetailsService(networkClient: NetworkClient(connectionErrorMapper: ConnectionErrorMapper()))), movie: Movie(id: 1022787, title: "Elio", overview: "overview", posterPath: "posterPath", releaseDate: Date())))
        .environmentObject(Coordinator())
}
