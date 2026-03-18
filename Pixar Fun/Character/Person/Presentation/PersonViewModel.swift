//
//  PersonViewModel.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 27.12.2025.
//

import Foundation
import Combine

class PersonViewModel: ViewModel {
    
    private let repository: PersonRepository
    private let cast: Cast
    private var page: Int = 1
    
    @Published private(set) var state: PersonState = .loading
    
    init(repository: PersonRepository, cast: Cast) {
        self.repository = repository
        self.cast = cast
    }
    
    func load() {
        addTask { @MainActor in
            do {
                let person = try await self.repository.getPerson(personId: self.cast.id)
                let photos = try await self.repository.getPersonImages(personId: self.cast.id)
                let page = try await self.repository.getMoviesWithPerson(personId: self.cast.id, page: self.page)
                self.state = .content(person, photos, page.results)
            } catch {
                log(error.localizedDescription)
                self.state = .error(error)
            }
        }
    }
}
