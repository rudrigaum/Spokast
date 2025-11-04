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

        navigationController.pushViewController(viewController, animated: true)
    }
}
