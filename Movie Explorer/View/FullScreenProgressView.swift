//
//  FullScreenProgressView.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 07.12.2025.
//

import SwiftUI

struct FullScreenProgressView: View {
    var body: some View {
        ZStack {
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FullScreenProgressView()
}
