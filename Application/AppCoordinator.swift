//
//  AppCoordinator.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/09/25.
//

import Foundation
import UIKit

final class AppCoordinator: Coordinator {
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let viewController = UIViewController()
        viewController.title = "Home"
        viewController.view.backgroundColor = .systemMint

        navigationController.pushViewController(viewController, animated: false)
    }
}
