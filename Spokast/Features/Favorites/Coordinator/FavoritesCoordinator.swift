//
//  FavoritesCoordinator.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 23/12/25.
//

import Foundation
import UIKit

@MainActor
final class FavoritesCoordinator: Coordinator {
    
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let viewModel = FavoritesViewModel()
        let viewController = FavoritesViewController(viewModel: viewModel)
        viewController.coordinator = self
        viewController.title = "Library"
        navigationController.pushViewController(viewController, animated: false)
    }
}

// MARK: - Navigation Delegate
extension FavoritesCoordinator: PodcastSelectionDelegate {
    
    func didSelectPodcast(_ podcast: Podcast) {
        let legacyRepository = FavoritesRepository()
        let detailViewModel = PodcastDetailViewModel(podcast: podcast, favoritesRepository: legacyRepository)
        let detailVC = PodcastDetailViewController(viewModel: detailViewModel)
        detailVC.coordinator = self
        navigationController.pushViewController(detailVC, animated: true)
    }
}


extension FavoritesCoordinator: PodcastDetailCoordinatorDelegate {}
