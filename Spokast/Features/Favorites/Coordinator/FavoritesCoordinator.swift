//
//  FavoritesCoordinator.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 23/12/25.
//

import Foundation
import UIKit

final class FavoritesCoordinator: Coordinator {
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let repository = FavoritesRepository()
        let viewModel = FavoritesViewModel(repository: repository)
        let viewController = FavoritesViewController(viewModel: viewModel)
        viewController.coordinator = self
        navigationController.pushViewController(viewController, animated: false)
    }
}

extension FavoritesCoordinator: PodcastSelectionDelegate {
    func didSelectPodcast(_ podcast: Podcast) {
            let service = APIService()
            let favoritesRepository = FavoritesRepository()
            
            let detailViewModel = PodcastDetailViewModel(
                podcast: podcast,
                service: service,
                favoritesRepository: favoritesRepository
            )
            
            let detailVC = PodcastDetailViewController(viewModel: detailViewModel)
            
            navigationController.pushViewController(detailVC, animated: true)
        }
}
