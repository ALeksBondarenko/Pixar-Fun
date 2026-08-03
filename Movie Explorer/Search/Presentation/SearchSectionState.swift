//
//  SearchSectionState.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 03.08.2026.
//

import Foundation

struct SearchSectionState<Item: Identifiable> {
    var items: [Item] = []
    var currentPage: Int = 0
    var totalPages: Int = 1
    var isLoadingNextPage: Bool = false
    var initialError: Error?
    var pageError: Error?

    var canLoadMore: Bool {
        currentPage < totalPages
    }
}

// Movie and Cast already expose a stable `id: Int`; conforming them to
// Identifiable here (Search-local) lets pagination de-duplicate appended
// pages without touching their original entity declarations.
extension Movie: Identifiable {}
extension Cast: Identifiable {}
