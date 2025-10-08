//
//  HomeView.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/09/25.
//

import Foundation
import UIKit

final class HomeView: UIView {

    // MARK: - UI Components
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Welcome to Spokast"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        return label
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout();
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Methods
    private func setupLayout() {
        setupHierarchy()
        setupConstraints()
        setupConfigurations()
    }

    private func setupHierarchy() {
        addSubview(welcomeLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            welcomeLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            welcomeLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }

    private func setupConfigurations() {
        backgroundColor = .systemBackground 
    }
}   
