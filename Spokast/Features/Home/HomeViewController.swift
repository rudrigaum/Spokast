//
//  HomeViewController.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/09/25.
//

import Foundation
import UIKit

final class HomeViewController: UIViewController {

    private let viewModel: HomeViewModel
    
    // MARK: - Initialization
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    // MARK: - Private Methods

    private func setupView() {
        view.backgroundColor = .systemBackground
        title = "Spokast"
    }
}

// MARK: - HomeViewModelDelegate
extension HomeViewController: HomeViewModelDelegate {

}
