//
//  VideoView.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 11.12.2025.
//

import SwiftUI
import WebKit

struct VideoView: UIViewRepresentable {
    
    let videoID: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let cleanID = sanitizeID(videoID)
        uiView.loadHTMLString(makeEmbedHTML(src: cleanID), baseURL: URL(string: "https://www.youtube-nocookie.com"))
    }
    
    private func sanitizeID(_ raw: String) -> String {
           raw.components(separatedBy: ["?", "&"]).first ?? raw
       }
    
    private func makeEmbedHTML(src: String) -> String {
            """
            <html>
            <head>
                <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0">
            </head>
            <body style="margin:0; padding:0; background:black;">
                <iframe
                    width="100%"
                    height="100%"
                    src="https://www.youtube-nocookie.com/embed/\(src)?playsinline=1&modestbranding=1&rel=0&enablejsapi=1&origin=https://www.youtube-nocookie.com"
                    frameborder="0"
                    allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
                    allowfullscreen>
                </iframe>
            </body>
            </html>
            """
        }
}

