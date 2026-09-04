//
//  AppCoordinator.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/09/25.
//

import UIKit

final class AppCoordinator: Coordinator {

    // MARK: - Properties
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    let window: UIWindow

    // MARK: - Initialization
    init(window: UIWindow) {
        self.window = window
        navigationController = UINavigationController()
    }

    // MARK: - Coordinator
    func start() {
        let homeNavigationController = makeHomeFlow()
        let favoritesNavigationController = makeFavoritesFlow()
        let profileNavigationController = makeProfileFlow()

        let viewControllers = [
            homeNavigationController,
            favoritesNavigationController,
            profileNavigationController
        ]

        let mainTabBarController = MainTabBarController(
            viewControllers: viewControllers
        )

        window.rootViewController = mainTabBarController
        window.makeKeyAndVisible()
    }

    // MARK: - Flow Factories
    private func makeHomeFlow() -> UINavigationController {
        let navigationController = UINavigationController()

        navigationController.tabBarItem = UITabBarItem(
            title: "Discover",
            image: UIImage(systemName: "waveform"),
            selectedImage: UIImage(systemName: "waveform.circle.fill")
        )

        let coordinator = HomeCoordinator(
            navigationController: navigationController
        )

        childCoordinators.append(coordinator)
        coordinator.start()

        return navigationController
    }

    private func makeFavoritesFlow() -> UINavigationController {
        let navigationController = UINavigationController()

        navigationController.tabBarItem = UITabBarItem(
            title: "Favorites",
            image: UIImage(systemName: "star"),
            selectedImage: UIImage(systemName: "star.fill")
        )

        let coordinator = FavoritesCoordinator(
            navigationController: navigationController
        )

        childCoordinators.append(coordinator)
        coordinator.start()

        return navigationController
    }

    private func makeProfileFlow() -> UINavigationController {
        let navigationController = UINavigationController()

        navigationController.tabBarItem = UITabBarItem(
            title: "Profile",
            image: UIImage(systemName: "person.circle"),
            selectedImage: UIImage(systemName: "person.circle.fill")
        )

        let coordinator = ProfileCoordinator(
            navigationController: navigationController
        )

        childCoordinators.append(coordinator)
        coordinator.start()

        return navigationController
    }
}
