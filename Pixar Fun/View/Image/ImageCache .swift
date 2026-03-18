//
//  ImageCache .swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 22.01.2026.
//

import Foundation
import UIKit

final class ImageCache {
    
    static let shared = ImageCache()
    
    private let cache = NSCache<NSURL, UIImage>()
    
    private init() {
        cache.countLimit = 200
    }
    
    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }
    
    func setImage(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}
