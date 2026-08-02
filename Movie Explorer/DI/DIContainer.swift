//
//  DIContainer.swift
//  Movie Explorer
//
//  Created by Александр Бондаренко on 14.02.2026.
//

import Foundation
import Swinject
import SwinjectAutoregistration

@MainActor
final class DIContainer {
    
    static var shared = DIContainer()
    
    let container: Container
    
    private init() {
        container = Container()
        register()
    }
    
    private func register() {
        container
            .autoregister(ConnectionErrorMapper.self, initializer: ConnectionErrorMapper.init)
            .inObjectScope(.container)

        container
            .register(SessionStore.self) { _ in KeychainSessionStore() }
            .inObjectScope(.container)

        container
            .autoregister(SessionTokenProvider.self, initializer: DefaultSessionTokenProvider.init)
            .inObjectScope(.container)

        container
            .register(URLSession.self) { _ in URLSession.shared }
            .inObjectScope(.container)

        container
            .autoregister(NetworkClient.self, initializer: NetworkClient.init)
            .inObjectScope(.container)

        container
            .autoregister(WebAuthPresenter.self, initializer: WebAuthPresenter.init)
            .inObjectScope(.container)

        container
            .register(WebAuthPresenting.self) { resolver in
                resolver.resolve(WebAuthPresenter.self)!
            }
            .inObjectScope(.container)

        container
            .autoregister(AuthService.self, initializer: AuthService.init)
            .inObjectScope(.container)

        container
            .register(AuthServiceProtocol.self) { resolver in
                resolver.resolve(AuthService.self)!
            }
            .inObjectScope(.container)

        container
            .autoregister(AuthRepository.self, initializer: AuthRepositoryImpl.init)
            .inObjectScope(.container)

        container
            .autoregister(PersonService.self, initializer: PersonService.init)
            .inObjectScope(.container)
        
        container
            .register(PersonServiceProtocol.self) { resolver in
                resolver.resolve(PersonService.self)!
            }
            .inObjectScope(.container)
        
        container
            .autoregister(PersonRepository.self, initializer: PersonRepositoryImpl.init)
            .inObjectScope(.container)
        
        container
            .autoregister(
                PersonViewModel.self,
                argument: Cast.self,
                initializer: PersonViewModel.init)
            .inObjectScope(.transient)
        
        container
            .autoregister(FavoriteService.self, initializer: FavoriteService.init)
            .inObjectScope(.container)
        
        container
            .register(FavoriteServiceProtocol.self) { resolver in
                resolver.resolve(FavoriteService.self)!
            }
            .inObjectScope(.container)
        
        container
            .autoregister(FavoriteRepository.self, initializer: FavoriteRepositoryImpl.init)
            .inObjectScope(.container)
        
        container
            .autoregister(FavotireMoviesViewModel.self, initializer: FavotireMoviesViewModel.init)
            .inObjectScope(.transient)
        
        container
            .autoregister(MovieDetailsService.self, initializer: MovieDetailsService.init)
            .inObjectScope(.container)
        
        container
            .register(MovieDetailsServiceProtocol.self) { resolver in
                resolver.resolve(MovieDetailsService.self)!
            }
            .inObjectScope(.container)
        
        container
            .autoregister(MovieDetailRepository.self, initializer: MovieDetailRepositoryImpl.init)
            .inObjectScope(.container)
        
        container
            .autoregister(
                MovieDetailsViewModel.self,
                argument: Movie.self,
                initializer: MovieDetailsViewModel.init
            )
            .inObjectScope(.transient)
        
        container
            .autoregister(
                GenreByMoviesViewModel.self,
                argument: Genres.self,
                initializer: GenreByMoviesViewModel.init
            )
            .inObjectScope(.transient)
        
        container
            .autoregister(MoviesService.self, initializer: MoviesService.init)
            .inObjectScope(.container)
        
        container
            .register(MoviesServiceProtocol.self) { resolver in
                resolver.resolve(MoviesService.self)!
            }
            .inObjectScope(.container)
        
        container
            .autoregister(MoviesRepository.self, initializer: MoviesRepositoryImpl.init)
            .inObjectScope(.container)
        
        container
            .autoregister(MoviesViewModel.self, initializer: MoviesViewModel.init)
            .inObjectScope(.transient)
        
        container
            .autoregister(SearchViewModel.self, initializer: SearchViewModel.init)
            .inObjectScope(.transient)
        
        container
            .autoregister(WatchListService.self, initializer: WatchListService.init)
            .inObjectScope(.container)
        
        container
            .register(WatchListServiceProtocol.self) { resolver in
                resolver.resolve(WatchListService.self)!
            }
            .inObjectScope(.container)
        
        container
            .autoregister(WatchListRepository.self, initializer: WatchListRepositoryImpl.init)
            .inObjectScope(.container)
        
        container
            .autoregister(WatchListViewModel.self, initializer: WatchListViewModel.init)
            .inObjectScope(.transient)
    }
}
