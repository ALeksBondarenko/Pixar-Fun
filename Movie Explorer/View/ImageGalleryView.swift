//
//  ImageGalleryView.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 04.08.2026.
//

import SwiftUI

/// Full-screen, swipeable, zoomable viewer for a set of TMDB image paths.
/// Presented once per screen (not once per thumbnail) so swiping between
/// images is possible; each page owns its own zoom/pan state.
///
/// `currentIndex` is a binding rather than private state so the presenting
/// screen can observe it and, e.g., auto-scroll its own thumbnail row to
/// stay in sync as the user swipes here.
struct ImageGalleryView: View {
    let images: [String]
    @Binding var currentIndex: Int
    @SwiftUI.Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            TabView(selection: $currentIndex) {
                ForEach(images.indices, id: \.self) { index in
                    ZoomableImagePage(path: images[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            Button {
                dismiss()
            } label: {
                Label("close", systemImage: "xmark")
                    .labelStyle(.iconOnly)
            }
            .foregroundStyle(.gray)
            .padding(16)
            .background(Color.gray.opacity(0.2))
            .clipShape(Circle())
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

private struct ZoomableImagePage: View {
    let path: String

    @State private var currentScale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var currentOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1
    private let maxScale: CGFloat = 5
    private let doubleTapScale: CGFloat = 2.5

    var body: some View {
        GeometryReader { geometry in
            Group {
                if currentScale > minScale {
                    imageContent
                        .highPriorityGesture(panGesture(in: geometry.size))
                } else {
                    imageContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(magnificationGesture)
            .onTapGesture(count: 2) {
                toggleZoom()
            }
        }
    }

    private var imageContent: some View {
        CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/original\(path)")) { image in
            image.resizable()
                .scaledToFit()
        } placeholder: {
            ProgressView()
        } failure: { _ in
            ProgressView()
        }
        .scaleEffect(currentScale)
        .offset(currentOffset)
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                currentScale = clampedScale(lastScale * value)
            }
            .onEnded { _ in
                lastScale = currentScale
                if currentScale <= minScale {
                    resetZoom(animated: true)
                }
            }
    }

    private func panGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let proposed = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                currentOffset = clampedOffset(proposed, in: size)
            }
            .onEnded { _ in
                lastOffset = currentOffset
            }
    }

    private func toggleZoom() {
        if currentScale > minScale {
            resetZoom(animated: true)
        } else {
            withAnimation(.spring) {
                currentScale = doubleTapScale
                lastScale = doubleTapScale
            }
        }
    }

    private func resetZoom(animated: Bool) {
        let apply = {
            currentScale = minScale
            lastScale = minScale
            currentOffset = .zero
            lastOffset = .zero
        }
        if animated {
            withAnimation(.spring) { apply() }
        } else {
            apply()
        }
    }

    private func clampedScale(_ scale: CGFloat) -> CGFloat {
        min(max(scale, minScale), maxScale)
    }

    private func clampedOffset(_ offset: CGSize, in size: CGSize) -> CGSize {
        let maxX = size.width * (currentScale - 1) / 2
        let maxY = size.height * (currentScale - 1) / 2
        guard maxX > 0, maxY > 0 else { return .zero }
        return CGSize(
            width: min(max(offset.width, -maxX), maxX),
            height: min(max(offset.height, -maxY), maxY)
        )
    }
}

#Preview {
    ImageGalleryView(
        images: [
            "/z3TNKTnIV64aqr0TQzEPArivkQ3.jpg",
            "/12tvpCv413QvvJlZGf4lRq446tT.jpg",
        ],
        currentIndex: .constant(0)
    )
}
