//
//  ProfileViewController.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 24/01/26.
//

import Foundation
import UIKit
import Combine
import UniformTypeIdentifiers

final class ProfileViewController: UIViewController {
    
    // MARK: - Dependencies
    private let viewModel: ProfileViewModelProtocol
    
    // MARK: - View
    private var customView: ProfileView {
        return view as! ProfileView
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init(viewModel: ProfileViewModelProtocol? = nil) {
        self.viewModel = viewModel ?? ProfileViewModel()
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
        setupTargets()
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupTargets() {
        customView.importButton.addTarget(self, action: #selector(didTapImport), for: .touchUpInside)
    }
    
    private func setupBindings() {
        viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    @objc private func didTapImport() {
        let supportedTypes: [UTType] = [.xml]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }
    
    private func handleStateChange(_ state: ProfileViewState) {
        switch state {
        case .idle:
            customView.setLoading(false)
            
        case .loading:
            customView.setLoading(true)
            
        case .success(let message):
            customView.setLoading(false)
            showAlert(title: "Success", message: message)
            
        case .error(let message):
            customView.setLoading(false)
            showAlert(title: "Error", message: message)
        }
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
