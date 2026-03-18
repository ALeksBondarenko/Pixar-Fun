//
//  PosterView.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 28.12.2025.
//

import SwiftUI

struct PosterView: View {
    let movie: Movie
    
    var body: some View {
        VStack {
            AsyncPosterImage(posterPath: movie.posterPath)
            
            Text(movie.title)
                .font(.body.bold())
                .padding(.bottom)
                .lineLimit(1)
        }
    }
}

#Preview {
    PosterView(movie: Movie(id: 1327819, title: "Hoppers", overview: "", posterPath: "/12tvpCv413QvvJlZGf4lRq446tT.jpg", releaseDate: Date()))
}
