//
//  AppCoordinator.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/09/25.
//

import Foundation
import UIKit

final class AppCoordinator: Coordinator {
    
    var window: UIWindow
    
    private let tabBarController = UITabBarController()
    private var childCoordinators = [Coordinator]()
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func start() {
        let homeNavController = UINavigationController()
        homeNavController.tabBarItem = UITabBarItem(
            title: "Discover",
            image: UIImage(systemName: "waveform"),
            selectedImage: UIImage(systemName: "waveform.circle.fill")
        )
        let homeCoordinator = HomeCoordinator(navigationController: homeNavController)
        childCoordinators.append(homeCoordinator)
        homeCoordinator.start()
        
        let favNavController = UINavigationController()
        favNavController.tabBarItem = UITabBarItem(
            title: "Favorites",
            image: UIImage(systemName: "star"),
            selectedImage: UIImage(systemName: "star.fill")
        )
        let favCoordinator = FavoritesCoordinator(navigationController: favNavController)
        childCoordinators.append(favCoordinator)
        favCoordinator.start()
        
        let searchNav = UINavigationController()
        let searchCoordinator = SearchCoordinator(navigationController: searchNav)
        childCoordinators.append(searchCoordinator)
        searchCoordinator.start()
        
        tabBarController.viewControllers = [homeNavController, favNavController, searchNav]
        tabBarController.tabBar.tintColor = .systemPurple
        tabBarController.tabBar.backgroundColor = .systemBackground
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
    }
}
