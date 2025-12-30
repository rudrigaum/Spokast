//
//  AppCoordinator.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/09/25.
//

import Foundation
import UIKit

final class AppCoordinator: Coordinator {
    
    // MARK: - Properties
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    let window: UIWindow
    
    // MARK: - Init
    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
    }
    
    // MARK: - Start
    func start() {
        let homeNav = makeHomeFlow()
        let searchNav = makeSearchFlow()
        let favNav = makeFavoritesFlow()
        
        let viewControllers = [homeNav, searchNav, favNav]
        let mainTabBar = MainTabBarController(viewControllers: viewControllers)
        
        window.rootViewController = mainTabBar
        window.makeKeyAndVisible()
    }
    
    // MARK: - Private Factory Methods
    private func makeHomeFlow() -> UINavigationController {
        let navController = UINavigationController()
        navController.tabBarItem = UITabBarItem(
            title: "Discover",
            image: UIImage(systemName: "waveform"),
            selectedImage: UIImage(systemName: "waveform.circle.fill")
        )
        
        let coordinator = HomeCoordinator(navigationController: navController)
        childCoordinators.append(coordinator)
        coordinator.start()
        
        return navController
    }
    
    private func makeSearchFlow() -> UINavigationController {
        let navController = UINavigationController()
        navController.tabBarItem = UITabBarItem(
            title: "Search",
            image: UIImage(systemName: "magnifyingglass"),
            selectedImage: UIImage(systemName: "magnifyingglass.circle.fill")
        )
        
        let coordinator = SearchCoordinator(navigationController: navController)
        childCoordinators.append(coordinator)
        coordinator.start()
        
        return navController
    }
    
    private func makeFavoritesFlow() -> UINavigationController {
        let navController = UINavigationController()
        navController.tabBarItem = UITabBarItem(
            title: "Favorites",
            image: UIImage(systemName: "star"),
            selectedImage: UIImage(systemName: "star.fill")
        )
        
        let coordinator = FavoritesCoordinator(navigationController: navController)
        childCoordinators.append(coordinator)
        coordinator.start()
        
        return navController
    }
}
