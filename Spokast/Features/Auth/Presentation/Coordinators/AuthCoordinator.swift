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
    var onFinish: (() -> Void)?
    var initialMode: LoginViewModel.AuthMode = .signIn
    
    // MARK: - Init
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    // MARK: - Coordinator Methods
    func start() {
        let authService = FirebaseAuthService()
        let authUseCase = AuthUseCase(authService: authService)
        let viewModel = LoginViewModel(authUseCase: authUseCase, initialMode: initialMode)

        viewModel.onSuccess = { [weak self] in
            self?.finish()
        }

        let viewController = LoginViewController(viewModel: viewModel)
        let authNavController = UINavigationController(rootViewController: viewController)
        authNavController.modalPresentationStyle = .pageSheet
        navigationController.present(authNavController, animated: true)
    }

    func finish() {
        navigationController.dismiss(animated: true) { [weak self] in
            self?.onFinish?()
        }
    }
}
