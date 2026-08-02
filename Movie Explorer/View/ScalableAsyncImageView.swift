//
//  MovieImageView.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 12.12.2025.
//

import SwiftUI

struct ScalableAsyncImageView: View {
    
    let string: String
    
    @State private var showFullScreen = false
    
    @State var currentScale = 1.0
    @State var lastScale = 0.0
    
    @State private var currentOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(string)")) { image in
            image.resizable()
        } placeholder: {
            ProgressView()
        } failure: { _ in
            ProgressView()
        }
        .cornerRadius(16)
        .aspectRatio(contentMode: .fit)
        .onTapGesture {
            showFullScreen = true
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            ZStack(alignment: .topLeading) {
                CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/original\(string)")) { image in
                    image.resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                } failure: { _ in
                    ProgressView()
                }
                .scaleEffect(currentScale)
                .offset(currentOffset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            handleScaleChange(value)
                        }
                        .onEnded { value in
                            lastScale = currentScale
                        }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Button(action: {
                    showFullScreen = false
                }) {
                    Label("close", systemImage: "xmark")
                        .labelStyle(.iconOnly)
                }
                .foregroundStyle(.gray)
                .padding(16)
                .background(Color.gray.opacity(0.2))
                .clipShape(Circle())
                .padding(.horizontal, 16)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
    
    private func handleScaleChange(_ zoom: CGFloat) {
        currentScale = lastScale + zoom - (lastScale == 0 ? 0 : 1)
    }
    
    private func handleOffsetChange(_ offset: CGSize) {
        var newOffset: CGSize = .zero
        
        newOffset.width = offset.width + lastOffset.width
        newOffset.height = offset.height + lastOffset.height
        
        currentOffset = newOffset
    }
}

#Preview {
    ScalableAsyncImageView(string: "/z3TNKTnIV64aqr0TQzEPArivkQ3.jpg")
}
