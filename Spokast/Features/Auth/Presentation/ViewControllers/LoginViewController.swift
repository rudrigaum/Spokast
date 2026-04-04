//
//  LoginViewController.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 27/02/26.
//

import Foundation
import UIKit
import Combine

final class LoginViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: LoginViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private var loginView: LoginView {
        guard let customView = view as? LoginView else {
            fatalError("Expected view to be of type LoginView. Verify your loadView() method implementation.")
        }
        return customView
    }

    // MARK: - Init
    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func loadView() {
        view = LoginView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupBindings()
        setupActions()
    }
    
    private func setupNavigationBar() {
        title = "Authentication"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(didTapCancel)
        )
    }
    
    // MARK: - Bindings (The Glue)
    private func setupBindings() {
        loginView.emailTextField.addTarget(self, action: #selector(emailChanged), for: .editingChanged)
        loginView.passwordTextField.addTarget(self, action: #selector(passwordChanged), for: .editingChanged)
        
        viewModel.$authMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode in
                self?.loginView.submitButton.setTitle(mode.title, for: .normal)
                self?.loginView.toggleModeButton.setTitle(mode.toggleTitle, for: .normal)
            }
            .store(in: &cancellables)
            
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.loginView.submitButton.configuration?.showsActivityIndicator = isLoading
                self?.loginView.submitButton.isEnabled = !isLoading
            }
            .store(in: &cancellables)
            
        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showAlert(message: message)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    private func setupActions() {
        loginView.submitButton.addTarget(self, action: #selector(didTapSubmit), for: .touchUpInside)
        loginView.toggleModeButton.addTarget(self, action: #selector(didTapToggle), for: .touchUpInside)
    }
    
    @objc private func emailChanged(_ sender: UITextField) {
        viewModel.email = sender.text ?? ""
    }
    
    @objc private func passwordChanged(_ sender: UITextField) {
        viewModel.password = sender.text ?? ""
    }
    
    @objc private func didTapSubmit() {
        viewModel.submit()
    }
    
    @objc private func didTapToggle() {
        viewModel.toggleAuthMode()
    }
    
    @objc private func didTapCancel() {
        dismiss(animated: true)
    }
}
