//
//  ProfileViewController.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 24/01/26.
//

import UIKit
import Combine
import UniformTypeIdentifiers

final class ProfileViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: ProfileViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - View
    private var customView: ProfileView {
        return view as! ProfileView
    }
    
    // MARK: - Init
    init(viewModel: ProfileViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func loadView() {
        self.view = ProfileView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupActions()
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupActions() {
        customView.backupButton.addTarget(self, action: #selector(didTapImport), for: .touchUpInside)
        customView.actionButton.addTarget(self, action: #selector(didTapAuthAction), for: .touchUpInside)
    }
    
    private func setupBindings() {
        viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - State Management
    private func handleStateChange(_ state: ProfileViewState) {
        customView.render(state: state)

        switch state {
        case .authenticated(_, let message):
            if let successMessage = message {
                showAlert(title: "Sucesso", message: successMessage)
            }
        case .error(let message):
            showAlert(title: "Erro", message: message)
        default:
            break
        }
    }
    
    // MARK: - Actions
    @objc private func didTapAuthAction() {
        viewModel.logout() 
    }
    
    @objc private func didTapImport() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.xml])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate
extension ProfileViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        viewModel.importOPML(from: url)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("User cancelled document picker")
    }
}
