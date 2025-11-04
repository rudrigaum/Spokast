//
//  PodcastCell.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 08/10/25.
//

import Foundation
import UIKit
import Kingfisher

final class PodcastCell: UITableViewCell {

    static let reuseIdentifier = "PodcastCell"

    // MARK: - UI Components
    private let podcastImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.numberOfLines = 2
        return label
    }()
    
    private let publisherLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(title: String, publisher: String, imageUrlString: String) {
        titleLabel.text = title
        publisherLabel.text = publisher
        
        guard let imageUrl = URL(string: imageUrlString) else {
            podcastImageView.image = UIImage(systemName: "mic.slash.circle")
            return
        }
        
        let placeholder = UIImage(systemName: "mic.circle.fill")
        let options: KingfisherOptionsInfo = [
            .transition(.fade(0.3)),
            .cacheOriginalImage
        ]
        
        podcastImageView.kf.setImage(
            with: imageUrl,
            placeholder: placeholder,
            options: options
        )
    }

    // MARK: - UI Setup
    private func setupUI() {
        let textStackView = UIStackView(arrangedSubviews: [titleLabel, publisherLabel])
        textStackView.axis = .vertical
        textStackView.spacing = 4
        
        let mainStackView = UIStackView(arrangedSubviews: [podcastImageView, textStackView])
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.axis = .horizontal
        mainStackView.spacing = 12
        mainStackView.alignment = .center
        
        contentView.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            podcastImageView.widthAnchor.constraint(equalToConstant: 70),
            podcastImageView.heightAnchor.constraint(equalToConstant: 70),
            
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        podcastImageView.kf.cancelDownloadTask()
        podcastImageView.image = nil
        titleLabel.text = nil
        publisherLabel.text = nil
    }
}
