//
//  AuthCoordinator.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 27/02/26.
//

import Foundation
import UIKit

@MainActor
final class AuthCoordinator: NavigationCoordinator {
    
    // MARK: - Properties
    var navigationController: UINavigationController
    weak var parentCoordinator: NavigationCoordinator?
    
    // MARK: - Init
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    // MARK: - Coordinator Methods
    func start() {
        let authService = FirebaseAuthService()
        let viewModel = LoginViewModel(authService: authService)
        let viewController = LoginViewController(viewModel: viewModel)
        let authNavController = UINavigationController(rootViewController: viewController)
        authNavController.modalPresentationStyle = .pageSheet
        navigationController.present(authNavController, animated: true)
    }
    
    func finish() {
        navigationController.dismiss(animated: true)
    }
}
