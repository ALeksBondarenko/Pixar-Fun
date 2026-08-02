//
//  AboutView.swift
//  Movie Explorer
//

import SwiftUI

struct AboutView: View {

    @SwiftUI.Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("aboutDisclaimer")
                    .font(.body)

                Link("aboutTMDBLinkTitle", destination: URL(string: "https://www.themoviedb.org")!)
                    .font(.body)

                Spacer()
            }
            .padding()
            .navigationTitle("aboutTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AboutView()
}
