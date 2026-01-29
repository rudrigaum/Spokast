//
//  SearchCoordinator.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 29/12/25.
//

import UIKit

final class SearchCoordinator: Coordinator {
    
    // MARK: - Properties
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Init
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    // MARK: - Start
    func start() {
        let service = PodcastService()
        let viewModel = SearchViewModel(service: service)
        
        let viewController = SearchViewController(viewModel: viewModel)
        viewController.coordinator = self
        viewController.tabBarItem = UITabBarItem(
            title: "Search",
            image: UIImage(systemName: "magnifyingglass"),
            selectedImage: UIImage(systemName: "magnifyingglass")
        )
        
        navigationController.pushViewController(viewController, animated: false)
    }
}

// MARK: - Navigation Delegate
extension SearchCoordinator: PodcastSelectionDelegate {
    
    func didSelectPodcast(_ podcast: Podcast) {
        let favoritesRepository = FavoritesRepository()
        let detailViewModel = PodcastDetailViewModel(podcast: podcast, favoritesRepository: favoritesRepository)
        let detailVC = PodcastDetailViewController(viewModel: detailViewModel)
        detailVC.coordinator = self
        navigationController.pushViewController(detailVC, animated: true)
    }
}

extension SearchCoordinator: PodcastDetailCoordinatorDelegate {}
