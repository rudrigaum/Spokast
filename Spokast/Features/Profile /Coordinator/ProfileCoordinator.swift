//
//  ProfileCoordinator.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 25/01/26.
//

import Foundation
import UIKit

@MainActor
final class ProfileCoordinator: NavigationCoordinator {
    
    // MARK: - Properties
    var navigationController: UINavigationController
    
    // MARK: - Init
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    // MARK: - Coordinator Methods
    func start() {
        let viewModel = ProfileViewModel()
        let viewController = ProfileViewController(viewModel: viewModel)
        viewController.title = "Profile"
        navigationController.pushViewController(viewController, animated: false)
    }
}
