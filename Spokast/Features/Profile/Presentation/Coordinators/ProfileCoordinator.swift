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
    private var authCoordinator: AuthCoordinator?
    
    // MARK: - Init
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    // MARK: - Coordinator Methods
    func start() {
        let authService = FirebaseAuthService()
        let importService = OPMLImportService()
        let viewModel = ProfileViewModel(authService: authService, importService: importService)
        let viewController = ProfileViewController(viewModel: viewModel)
        
        viewModel.onLoginRequest = { [weak self, weak viewModel] isSignUp in
            let mode: LoginViewModel.AuthMode = isSignUp ? .signUp : .signIn
            
            self?.showAuthFlow(with: mode) {
                viewModel?.checkAuthStatus()
            }
        }
        
        viewController.title = "Profile"
        navigationController.pushViewController(viewController, animated: false)
    }
    
    func showAuthFlow(with mode: LoginViewModel.AuthMode, onDismiss: @escaping () -> Void) {
        let child = AuthCoordinator(navigationController: navigationController)
        child.parentCoordinator = self
        child.initialMode = mode
        
        child.onFinish = { [weak self] in
            self?.authCoordinator = nil
            onDismiss()
        }
        
        self.authCoordinator = child
        child.start()
    }
}
