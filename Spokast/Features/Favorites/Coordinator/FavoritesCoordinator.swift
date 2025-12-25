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
        let viewController = FavoritesViewController()
        navigationController.pushViewController(viewController, animated: false)
    }
}
