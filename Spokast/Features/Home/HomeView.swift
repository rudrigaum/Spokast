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
    let podcastsTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PodcastCell")
        return tableView
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
        addSubview(podcastsTableView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            podcastsTableView.topAnchor.constraint(equalTo: self.topAnchor),
            podcastsTableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            podcastsTableView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            podcastsTableView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    private func setupConfigurations() {
        backgroundColor = .systemBackground
    }
}
