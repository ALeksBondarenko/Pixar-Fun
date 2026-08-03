//
//  ImageLoader.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 22.01.2026.
//
import UIKit
import Combine

final class ImageLoader: ObservableObject {
    @Published var imageState: ImageState = .idle
    
    private let url: URL?
    private let cache: ImageCache
    private var task: Task<Void, Never>?
    
    init(url: URL?, cache: ImageCache = .shared) {
        self.url = url
        self.cache = cache
    }
    
    func load() {
        task?.cancel()
        
        self.imageState = .loading
        
        if let url = url {
            if let cached = cache.image(for: url) {
                self.imageState = .loaded(cached)
                return
            }
           
            task = Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let uiImage = UIImage(data: data) {
                        cache.setImage(uiImage, for: url)
                        self.imageState = .loaded(uiImage)
                    }
                } catch is CancellationError {
                    return
                } catch let urlError as URLError where urlError.code == .cancelled {
                    return
                } catch {
                    self.imageState = .failed(error)
                }
            }
        } else {
            self.imageState = .failed(LoadImageError.invalidURL)
            return
        }
    }
    
    func cancel() {
        task?.cancel()
    }
    
    deinit {
        task?.cancel()
    }
}
