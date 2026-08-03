//
//  PosterView.swift
//  Movie Explorer
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
                .frame(width: 164)
                .lineLimit(1)
        }
    }
}

#Preview {
    PosterView(movie: Movie(id: 1327819, title: "Some new film with long title", overview: "", posterPath: nil, releaseDate: Date()))
}
