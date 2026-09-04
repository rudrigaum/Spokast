//
//  HomeCoordinator.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/09/25.
//

import UIKit

final class HomeCoordinator: Coordinator {

    // MARK: - Properties
    var navigationController: UINavigationController

    // MARK: - Initialization
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Coordinator
    func start() {
        let podcastService = PodcastService()

        let homeViewModel = HomeViewModel(
            apiService: podcastService
        )

        let searchViewModel = SearchViewModel(
            service: podcastService
        )

        let viewController = HomeViewController(
            homeViewModel: homeViewModel,
            searchViewModel: searchViewModel
        )

        viewController.delegate = self

        navigationController.pushViewController(
            viewController,
            animated: true
        )
    }

    // MARK: - Navigation to Player
    func presentPlayer(
        for episode: Episode,
        podcastImageURL: URL?
    ) {
        let favoritesRepository = FavoritesRepository()

        let playerViewModel = PlayerViewModel(
            episode: episode,
            podcastImageURL: podcastImageURL,
            favoritesRepository: favoritesRepository
        )

        let playerViewController = PlayerViewController(
            viewModel: playerViewModel
        )

        if let sheet = playerViewController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }

        navigationController.present(
            playerViewController,
            animated: true
        )
    }
}

// MARK: - HomeViewControllerDelegate
extension HomeCoordinator: HomeViewControllerDelegate {

    func didSelectPodcast(_ podcast: Podcast) {
        let favoritesRepository = FavoritesRepository()

        let detailViewModel = PodcastDetailViewModel(
            podcast: podcast,
            favoritesRepository: favoritesRepository
        )

        let detailViewController = PodcastDetailViewController(
            viewModel: detailViewModel
        )

        detailViewController.coordinator = self

        navigationController.pushViewController(
            detailViewController,
            animated: true
        )
    }
}

// MARK: - PodcastDetailCoordinatorDelegate
extension HomeCoordinator: PodcastDetailCoordinatorDelegate {

    func showEpisodeDetails(
        _ episode: Episode,
        from podcast: Podcast
    ) {
        let viewModel = EpisodeDetailViewModel(
            episode: episode,
            podcast: podcast
        )

        let episodeDetailViewController = EpisodeDetailViewController(
            viewModel: viewModel
        )

        navigationController.pushViewController(
            episodeDetailViewController,
            animated: true
        )
    }
}
