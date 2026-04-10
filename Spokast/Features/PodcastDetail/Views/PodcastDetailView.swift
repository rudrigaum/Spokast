//
//  PodcastDetailView.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 19/12/25.
//

import Foundation
import UIKit

final class PodcastDetailView: UIView {

    // MARK: - Actions
    var didSelectSortOption: ((EpisodeSorting) -> Void)?
    var didTapSortButton: (() -> Void)?

    // MARK: - UI Components
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .singleLine
        tableView.register(EpisodeCell.self, forCellReuseIdentifier: EpisodeCell.reuseIdentifier)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        return tableView
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private let artistLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()
    
    lazy var subscribeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .systemPurple
        config.baseForegroundColor = .white
        config.title = "Subscribe"
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.titleLabel?.numberOfLines = 1
        return button
    }()
    
    lazy var sortButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.cornerStyle = .medium
        config.baseBackgroundColor = .secondarySystemBackground
        config.baseForegroundColor = .label
        config.image = UIImage(systemName: "arrow.up.arrow.down")
        config.imagePlacement = .leading
        config.imagePadding = 6
        config.title = "Sort"
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
        button.showsMenuAsPrimaryAction = false
        button.addTarget(self, action: #selector(handleSortTap), for: .touchUpInside)
        return button
    }()
    
    private lazy var buttonsStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [subscribeButton, sortButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()
    
    private let genreLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        return label
    }()

    private lazy var headerStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel, artistLabel, buttonsStackView, genreLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        return stack
    }()
    
    private let headerContainerView: UIView = {
        let view = UIView()
        view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 450)
        return view
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Configuration
    func configure(with viewModel: PodcastDetailViewModel) {
        titleLabel.text = viewModel.title
        artistLabel.text = viewModel.artist
        genreLabel.text = viewModel.genre.uppercased()
        layoutTableHeaderView()
    }

    @objc private func handleSortTap() {
        didTapSortButton?()
    }
    
    func updateSubscribeButton(isSubscribed: Bool) {
        var config = subscribeButton.configuration
        subscribeButton.titleLabel?.numberOfLines = 1
        subscribeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        if isSubscribed {
            config?.baseBackgroundColor = .systemGray5
            config?.baseForegroundColor = .secondaryLabel
            config?.title = "Subscribed"
            config?.image = UIImage(systemName: "checkmark")
            config?.imagePadding = 4
            config?.imagePlacement = .leading
        } else {
            config?.baseBackgroundColor = .systemPurple
            config?.baseForegroundColor = .white
            config?.title = "Subscribe"
            config?.image = nil
        }
        
        UIView.transition(with: subscribeButton, duration: 0.2, options: .transitionCrossDissolve) {
            self.subscribeButton.configuration = config
        }
    }

    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .systemBackground
        addSubview(tableView)
        
        headerContainerView.addSubview(headerStackView)
        
        let stackLeading = headerStackView.leadingAnchor.constraint(
            equalTo: headerContainerView.leadingAnchor,
            constant: 24
        )
        let stackTrailing = headerStackView.trailingAnchor.constraint(
            equalTo: headerContainerView.trailingAnchor,
            constant: -24
        )

        stackLeading.priority = UILayoutPriority(999)
        stackTrailing.priority = UILayoutPriority(999)
        
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 200),
            imageView.widthAnchor.constraint(equalToConstant: 200),
            
            headerStackView.topAnchor.constraint(equalTo: headerContainerView.topAnchor, constant: 32),
            headerStackView.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor, constant: -32),
            headerStackView.centerXAnchor.constraint(equalTo: headerContainerView.centerXAnchor),
            
            stackLeading,
            stackTrailing
        ])
        
        tableView.tableHeaderView = headerContainerView

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Layout Helper
    private func layoutTableHeaderView() {
        guard let header = tableView.tableHeaderView else { return }
        
        header.setNeedsLayout()
        header.layoutIfNeeded()
        
        let size = header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        
        if header.frame.height != size.height {
            header.frame.size.height = size.height
            tableView.tableHeaderView = header
        }
    }
}
