//
//  AsyncPosterImage.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 06.01.2026.
//

import SwiftUI

struct AsyncPosterImage: View {
    
    var posterPath: String?
    
    private let width: CGFloat = 164
    private let height: CGFloat = 256
    private let cornerRadius: CGFloat = 16
    
    var body: some View {
        if let posterPath = posterPath {
            CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")) { image in
                image.resizable()
            } placeholder: {
                Progress()
            } failure: { _ in
                Progress()
            }
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .aspectRatio(contentMode: .fill)
        } else {
            Error()
        }
    }
    
    @ViewBuilder
    private func Progress() -> some View {
        ZStack(alignment: .center){
            ProgressView()
        }
        .frame(width: width, height: height)
        .background { Background() }
    }
    
    @ViewBuilder
    private func Error() -> some View {
        ZStack(alignment: .center){
            Image("PosterPlaceholder")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.secondary)
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)
        }
        .frame(width: width, height: height)
        .background { Background() }
        .accessibilityLabel(Text("posterUnavailable"))
    }
    
    @ViewBuilder
    private func Background() -> some View {
        RoundedRectangle(cornerRadius: 16)
            .foregroundColor(Color("Background"))
            .shadow(color: Color.gray.opacity(0.2), radius: 10, x: 5, y: 5)
            .padding(5)
    }
}

#Preview {
    AsyncPosterImage(posterPath: "/12tvpCv413QvvJlZGf4lRq446tT.jpg")
}
