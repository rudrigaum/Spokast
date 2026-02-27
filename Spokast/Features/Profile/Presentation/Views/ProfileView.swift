//
//  ProfileView.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/02/26.
//

import Foundation
import UIKit

final class ProfileView: UIView {
    
    // MARK: - UI Components
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title2).bold()
        label.textAlignment = .center
        return label
    }()
    
    let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    let actionButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.buttonSize = .large
        let button = UIButton(configuration: config)
        return button
    }()
    
    let createAccountButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Create Account"
        config.buttonSize = .medium
        let button = UIButton(configuration: config)
        return button
    }()
    
    let backupButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = "Import OPML Backup"
        config.image = UIImage(systemName: "square.and.arrow.down")
        config.imagePadding = 8
        config.buttonSize = .medium
        let button = UIButton(configuration: config)
        return button
    }()
    
    let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = .systemBackground
        
        addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(statusLabel)
        stackView.addArrangedSubview(actionButton)
        stackView.addArrangedSubview(createAccountButton)
        stackView.setCustomSpacing(40, after: createAccountButton)
        stackView.addArrangedSubview(backupButton)
        
        addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            actionButton.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.8)
        ])
    }
    
    // MARK: - Public State Management
    func render(state: ProfileViewState) {
        switch state {
        case .loading:
            loadingIndicator.startAnimating()
            stackView.isHidden = true
            
        case .unauthenticated:
            loadingIndicator.stopAnimating()
            stackView.isHidden = false
            titleLabel.text = "Welcome to Spokast"
            statusLabel.text = "Sign in to sync your podcasts across all your devices."
            actionButton.setTitle("Sign In", for: .normal)
            actionButton.configuration?.baseBackgroundColor = .systemBlue
            createAccountButton.isHidden = false
            backupButton.isHidden = false
            
        case .authenticated(let user, let message):
            loadingIndicator.stopAnimating()
            stackView.isHidden = false
            titleLabel.text = "Hello, \(user.displayName ?? "User")"
            statusLabel.text = message ?? user.email
            actionButton.setTitle("Sign Out", for: .normal)
            actionButton.configuration?.baseBackgroundColor = .systemRed
            createAccountButton.isHidden = true
            backupButton.isHidden = false
            
        case .error(let message):
            loadingIndicator.stopAnimating()
            stackView.isHidden = false
            titleLabel.text = "Something went wrong"
            statusLabel.text = message
            statusLabel.textColor = .systemRed
            actionButton.setTitle("Try Again", for: .normal)
            createAccountButton.isHidden = false
            backupButton.isHidden = false
        }
    }
}
