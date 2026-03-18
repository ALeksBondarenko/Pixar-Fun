//
//  File.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 22.01.2026.
//

import Foundation
import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View, Failure: View>: View {
    @StateObject private var loader: ImageLoader
    
    private var content: (Image) -> Content
    private var placeholder: () -> Placeholder
    private var failure: (Error) -> Failure
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder failure: @escaping (Error) -> Failure,
    ) {
        _loader = StateObject(wrappedValue: ImageLoader(url: url))
        self.content = content
        self.placeholder = placeholder
        self.failure = failure
    }
    
    var body: some View {
        ZStack {
            switch loader.imageState {
            case .idle:
                placeholder()
            case .loading:
                placeholder()
            case .loaded(let uiImage):
                content(Image(uiImage: uiImage))
            case .failed(let error):
                failure(error)
            }
        }
        .onAppear {
            loader.load()
        }
        .onDisappear {
            loader.cancel()
        }
        
    }
}
