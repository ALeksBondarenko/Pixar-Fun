//
//  PersonView.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 27.12.2025.
//

import SwiftUI

struct PersonScreen: View {
    
    @StateObject var viewModel: PersonViewModel
    @EnvironmentObject private var coordinator: Coordinator
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                FullScreenProgressView()
            case .content(let person, let photos, let movies):
                PersonView(person: person, photos: photos, movies: movies)
            case .error(let error):
                ErrorView(error: error, onRetry: viewModel.load, onCancel: coordinator.pop)
            }
        }
        .onAppear {
            viewModel.load()
        }
        .onDisappear {
            viewModel.cancelAllTasks()
        }
    }
    
    @ViewBuilder
    func PersonView(person: Person, photos: [PersonImage], movies: [Movie]) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading){
                Header(person: person)
                    .padding(.horizontal)
                
                Spacer()
                
                Text("biography")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                
                Text(person.biography)
                    .font(.caption)
                    .truncationEffect(lenght: 3, moreText: "more", animation: .smooth(duration: 0.5, extraBounce: 0))
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(photos, id: \.filePath) { photo in
                            ScalableAsyncImageView(string: photo.filePath)
                                .frame(width: 160, height: 240)
                        }
                    }.padding(.horizontal)
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
                                .onTapGesture {
                                    coordinator.route(destination: .details(movie))
                                }
                        }
                    }
                    .padding(.horizontal, 15)
                }
            }
        }
    }
    
    @ViewBuilder
    func Header(person: Person)  -> some View {
        HStack(alignment: .top) {
            AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(person.profilePath)")) { image in
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
                
                Text(person.placeOfBirth)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
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
