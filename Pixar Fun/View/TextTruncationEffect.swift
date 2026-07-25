//
//  TextTruncationEffect.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 28.12.2025.
//

import SwiftUI

extension Text {
    
    @ViewBuilder
    func truncationEffect(lenght: Int, moreText: String, animation: Animation) -> some View {
        self.modifier(
            TruncationEffectViewModifier(lenght: lenght, moreText: moreText, animation: animation)
        )
    }
}

fileprivate struct TruncationEffectViewModifier: ViewModifier {
    var lenght: Int
    var moreText: String
    var animation: Animation
    
    @State var isEnabled: Bool = true
    
    @State private var limitedSize: CGSize = .zero
    @State private var fullSize: CGSize = .zero
    @State private var animatedProgress: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .lineLimit(lenght)
            .opacity(0)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGSize.self) {
                $0.size
            } action: { newValue in
                limitedSize = newValue
            }
            .frame(height: isExpanded ? fullSize.height : nil)
            .overlay {
                GeometryReader {
                    let contentSize = $0.size
                    
                    content
                        .textRenderer(TruncatedTextRender(lenght: lenght, moreText: String(localized: LocalizedStringResource(stringLiteral: moreText)), progress: animatedProgress))
                        .fixedSize(horizontal: false, vertical: true)
                        .onGeometryChange(for: CGSize.self) {
                            $0.size
                        } action: { newValue in
                            fullSize = newValue
                        }
                        .frame(
                            width: contentSize.width,
                            height: contentSize.height,
                            alignment: isExpanded ? .leading : .topLeading
                        )
                }
            }
            .clipped()
            .onChange(of: isEnabled) { oldValue, newValue in
                withAnimation(animation) {
                    animatedProgress = !newValue ? 1 : 0
                }
            }
            .onAppear {
                animatedProgress = !isEnabled ? 1 : 0
            }.onTapGesture {
                isEnabled.toggle()
            }
        
    }
    
    var isExpanded: Bool {
        animatedProgress == 1
    }
}

@Animatable
fileprivate struct TruncatedTextRender: TextRenderer {
    @AnimatableIgnored var lenght: Int
    @AnimatableIgnored var moreText: String
    var progress: CGFloat
    
    func draw(layout: Text.Layout, in ctx: inout GraphicsContext) {
        for (index, line) in layout.enumerated() {
            var copyContext = ctx
            if index == lenght - 1 {
                drawMoreTextAtTeheEnd(line: line, context: &copyContext)
            } else {
                copyContext.draw(line)
            }
        }
    }
    
    func drawMoreTextAtTeheEnd(line: Text.Layout.Element, context: inout GraphicsContext) {
        let runs = line.flatMap({ $0 })
        let runsCount = runs.count
        let textCount = moreText.count
        
        for index in 0..<max (runsCount - textCount, 0) {
            let run = runs[index]
            context.draw(run)
        }
        
        for index in max (runsCount - textCount, 0)..<runsCount {
            let run = runs[index]
            context.opacity = progress
            context.draw(run)
        }
        
        let textRunIndex = max (runsCount - textCount, 0)
        guard !runs.isEmpty else { return }
        let run = runs[textRunIndex]
        
        let typography = run.typographicBounds
        let fontSize: CGFloat = typography.ascent
        let font = UIFont.systemFont(ofSize: fontSize)
        
        let spacing: CGFloat = NSString(string: moreText).size(withAttributes: [
            .font: font
        ]).width
        
        let swiftUIText = Text("...\(moreText)")
            .font(Font(font))
            .foregroundStyle(.gray)
        
        let origin = CGPoint(
            x: typography.rect.minX + spacing,
            y: typography.rect.midY
        )
        
        context.opacity = 1 - progress
        context.draw(swiftUIText, at: origin)
    }
}

#Preview {
    PersonScreen(viewModel: PersonViewModel(repository: PersonRepositoryImpl(service: PersonService(networkClient: NetworkClient(
        connectionErrorMapper: ConnectionErrorMapper(),
        sessionTokenProvider: DefaultSessionTokenProvider(sessionStore: KeychainSessionStore()),
        urlSession: .shared
    ))), cast: Cast(id: 16828, character: "Buzz Lightyear (voice)", name: "Chris Evans", profilePath: "/3bOGNsHlrswhyW79uvIHH1V43JI.jpg")))
        .environmentObject(Coordinator())
}
