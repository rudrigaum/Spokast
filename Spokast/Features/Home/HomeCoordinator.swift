//
//  HomeCoordinator.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/09/25.
//

import Foundation
import UIKit

final class HomeCoordinator: Coordinator {
    
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let apiService = APIService()
        let viewModel = HomeViewModel(apiService: apiService)
        let viewController = HomeViewController(viewModel: viewModel)
        
        viewController.delegate = self
        
        navigationController.pushViewController(viewController, animated: true)
    }
    
    // MARK: - Navigation to Player
    func presentPlayer(for episode: Episode, podcastImageURL: URL?) {
        
        let favoritesRepository = FavoritesRepository()
        let playerViewModel = PlayerViewModel(
            episode: episode,
            podcastImageURL: podcastImageURL,
            favoritesRepository: favoritesRepository
        )
        
        let playerViewController = PlayerViewController(viewModel: playerViewModel)
        
        if let sheet = playerViewController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        
        navigationController.present(playerViewController, animated: true)
    }
}

// MARK: - HomeViewControllerDelegate
extension HomeCoordinator: HomeViewControllerDelegate {
    func didSelectPodcast(_ podcast: Podcast) {
        let favoritesRepository = FavoritesRepository()
        let detailViewModel = PodcastDetailViewModel(podcast: podcast, favoritesRepository: favoritesRepository)
        let detailViewController = PodcastDetailViewController(viewModel: detailViewModel)
        detailViewController.coordinator = self
        navigationController.pushViewController(detailViewController, animated: true)
    }
}

extension HomeCoordinator: PodcastDetailCoordinatorDelegate {}
