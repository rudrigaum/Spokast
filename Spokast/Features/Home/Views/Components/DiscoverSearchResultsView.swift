//
//  DiscoverSearchResultsView.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 01/09/26.
//

import Foundation
import UIKit

final class DiscoverSearchResultsView: UIView {

    // MARK: - UI Components
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.rowHeight = 100
        tableView.keyboardDismissMode = .onDrag
        tableView.register(
            PodcastCell.self,
            forCellReuseIdentifier: PodcastCell.reuseIdentifier
        )
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        showIdle()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupView() {
        backgroundColor = .systemBackground

        addSubview(tableView)
        addSubview(activityIndicator)
        addSubview(messageLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),

            messageLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 32
            ),
            messageLabel.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -32
            ),
            messageLabel.centerYAnchor.constraint(
                equalTo: centerYAnchor,
                constant: -50
            )
        ])
    }

    // MARK: - State
    func showIdle() {
        isHidden = true

        tableView.isHidden = true
        messageLabel.isHidden = true

        activityIndicator.stopAnimating()
    }

    func showLoading() {
        isHidden = false

        tableView.isHidden = true
        messageLabel.isHidden = true

        activityIndicator.startAnimating()
    }

    func showResults() {
        isHidden = false

        activityIndicator.stopAnimating()
        messageLabel.isHidden = true
        tableView.isHidden = false
    }

    func showMessage(_ message: String) {
        isHidden = false

        activityIndicator.stopAnimating()
        tableView.isHidden = true

        messageLabel.text = message
        messageLabel.isHidden = false
    }
}
