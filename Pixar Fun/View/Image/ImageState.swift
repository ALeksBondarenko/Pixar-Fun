//
//  ImageState.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 22.01.2026.
//

import Foundation
import UIKit

enum ImageState {
    case idle
    case loading
    case loaded(UIImage)
    case failed(Error)
}
