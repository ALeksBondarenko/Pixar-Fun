//
//  PersonView.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 03.08.2026.
//

import SwiftUI

struct PersonView: View {
    let cast: Cast
    
    var body: some View {
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
            
            if let character = cast.character {
                Text(character)
                    .font(.caption.bold())
            }
            
            Text(cast.name ?? "N/A")
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: 120)
    }
}

#Preview {
    PersonView(cast: Cast(id: 1, character: nil, name: "ddd", profilePath: nil))
}
