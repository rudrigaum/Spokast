//
//  FavoritesView.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 27/12/25.
//

import Foundation
import UIKit

final class FavoritesView: UIView {
    
    // MARK: - UI Components
    lazy var tableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .systemBackground
        table.separatorStyle = .singleLine
        table.register(FavoriteCell.self, forCellReuseIdentifier: FavoriteCell.reuseIdentifier)
        table.tableFooterView = UIView()
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .systemPurple
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "You haven't followed any podcasts yet.\nGo explore!"
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    func updateState(_ state: FavoritesViewState) {
        switch state {
        case .loading:
            activityIndicator.startAnimating()
            tableView.isHidden = true
            emptyLabel.isHidden = true
            
        case .empty:
            activityIndicator.stopAnimating()
            tableView.isHidden = true
            emptyLabel.isHidden = false
            
        case .content:
            activityIndicator.stopAnimating()
            tableView.isHidden = false
            emptyLabel.isHidden = true
        }
    }
    
    // MARK: - Layout
    private func setupLayout() {
        backgroundColor = .systemBackground
        
        addSubview(tableView)
        addSubview(emptyLabel)
        addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
