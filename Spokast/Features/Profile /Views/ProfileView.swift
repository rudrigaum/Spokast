//
//  ProfileView.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 24/01/26.
//

import Foundation
import UIKit

final class ProfileView: UIView {
    
    // MARK: - UI Components
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Settings"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    let importButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Import OPML File"
        config.image = UIImage(systemName: "square.and.arrow.down")
        config.imagePadding = 8
        config.cornerStyle = .medium
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let activityIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .systemBackground
        
        addSubview(stackView)
        addSubview(activityIndicator)
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(importButton)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
            
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    // MARK: - State Handling helpers
    func setLoading(_ isLoading: Bool) {
        if isLoading {
            activityIndicator.startAnimating()
            importButton.isEnabled = false
            importButton.alpha = 0.5
        } else {
            activityIndicator.stopAnimating()
            importButton.isEnabled = true
            importButton.alpha = 1.0
        }
    }
}
