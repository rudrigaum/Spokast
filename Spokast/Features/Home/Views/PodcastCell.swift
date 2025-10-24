//
//  PodcastCell.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 08/10/25.
//

import Foundation
import UIKit

final class PodcastCell: UITableViewCell {

    // MARK: - Properties
    static let reuseIdentifier = "PodcastCell"

    // MARK: - UI Components
    private let podcastImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        label.textColor = .label
        return label
    }()

    private let publisherLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var labelsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, publisherLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 4
        return stackView
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [podcastImageView, labelsStackView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center
        return stackView
    }()

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented for PodcastCell")
    }

    // MARK: - Public Methods
    func configure(title: String, publisher: String) {
        titleLabel.text = title
        publisherLabel.text = publisher
    }

    // MARK: - Private Methods
    private func setupLayout() {
        setupHierarchy()
        setupConstraints()
        setupConfigurations()
    }

    private func setupHierarchy() {
        contentView.addSubview(mainStackView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            podcastImageView.widthAnchor.constraint(equalToConstant: 70),
            podcastImageView.heightAnchor.constraint(equalTo: podcastImageView.widthAnchor),

            mainStackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }

    private func setupConfigurations() {
        accessoryType = .disclosureIndicator
    }
}
