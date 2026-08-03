//
//  PersonViewModel.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 27.12.2025.
//

import Foundation
import Combine

class PersonViewModel: ViewModel {
    
    private let repository: PersonRepository
    private let cast: Cast
    private var page: Int = 1
    private var totalPage: Int = 1
    
    @Published private(set) var state: PersonState = .loading
    
    init(repository: PersonRepository, cast: Cast) {
        self.repository = repository
        self.cast = cast
    }
    
    func load() {
        addTask { @MainActor in
            do {
                async let personResult = self.repository.getPerson(personId: self.cast.id)
                async let photosResult = self.repository.getPersonImages(personId: self.cast.id)
                async let pageResult = self.repository.getMoviesWithPerson(personId: self.cast.id, page: self.page)

                let (person, photos, page) = try await (personResult, photosResult, pageResult)
                
                self.totalPage = page.totalPages
                self.state = .content(person, photos, page.results)
            } catch {
                log(error.localizedDescription)
                self.state = .error(error)
            }
        }
    }
    
    func loadNextMoviePage() {
        guard page < totalPage else { return }
        guard case .content(let person, let photos, let movies) = state else { return }
        cancelAllTasks()
        addTask {
            do {
                let result = try await self.repository.getMoviesWithPerson(personId: self.cast.id, page: self.page + 1)
                defer { self.page += 1 }
                self.state = .content(person, photos, movies + result.results)
            } catch is CancellationError {
                return
            } catch let urlError as URLError where urlError.code == .cancelled {
                return
            } catch {
                log(error.localizedDescription)
                self.state = .error(error)
            }
        }
    }
}
