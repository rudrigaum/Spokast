//
//  EpisodeCell.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 20/12/25.
//

import Foundation
import UIKit
import Kingfisher

final class EpisodeCell: UITableViewCell {

    static let reuseIdentifier = "EpisodeCell"
    
    // MARK: - Actions
    var onPlayTap: (() -> Void)?
    
    // MARK: - UI Components
    private lazy var artworkContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private let artworkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private let overlayView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black.withAlphaComponent(0.4)
        return view
    }()
    
    private let playImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "play.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var textStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        return stack
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupGestures()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func prepareForReuse() {
        super.prepareForReuse()
        artworkImageView.kf.cancelDownloadTask()
        artworkImageView.image = nil
    }
    
    // MARK: - Configuration
    func configure(with episode: Episode, podcastArtURL: URL?, isPlaying: Bool) {
        titleLabel.text = episode.trackName
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let dateString = dateFormatter.string(from: episode.releaseDate)
        let durationText = formatDuration(millis: episode.trackTimeMillis)
        
        descriptionLabel.text = "\(dateString) • \(durationText)"
        
        let episodeURL = URL(string: episode.artworkUrl160 ?? episode.artworkUrl600 ?? "")
        let finalURL = episodeURL ?? podcastArtURL
        
        artworkImageView.kf.setImage(
            with: finalURL,
            placeholder: UIImage(systemName: "photo")
        )
        
        updatePlaybackState(isPlaying: isPlaying)
    }
    
    // MARK: - Helpers
    private func formatDuration(millis: Int?) -> String {
        guard let millis = millis else { return "-- min" }
        let seconds = millis / 1000
        let minutes = seconds / 60
        
        if minutes > 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes) min"
        }
    }
    
    func updatePlaybackState(isPlaying: Bool) {
        let iconName = isPlaying ? "pause.fill" : "play.fill"
        
        UIView.transition(with: playImageView, duration: 0.2, options: .transitionCrossDissolve) {
            self.playImageView.image = UIImage(systemName: iconName)
        }
    }
    
    // MARK: - Gestures
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPlayContainer))
        artworkContainer.addGestureRecognizer(tapGesture)
    }
    
    @objc private func didTapPlayContainer() {
        UIView.animate(withDuration: 0.1, animations: {
            self.artworkContainer.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.artworkContainer.transform = .identity
            }
        }
        onPlayTap?()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .systemBackground
        selectionStyle = .none
        
        contentView.addSubview(artworkContainer)
        artworkContainer.addSubview(artworkImageView)
        artworkContainer.addSubview(overlayView)
        artworkContainer.addSubview(playImageView)
        
        contentView.addSubview(textStackView)
        
        NSLayoutConstraint.activate([
            artworkContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            artworkContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            artworkContainer.heightAnchor.constraint(equalToConstant: 60),
            artworkContainer.widthAnchor.constraint(equalToConstant: 60),
            
            artworkImageView.topAnchor.constraint(equalTo: artworkContainer.topAnchor),
            artworkImageView.bottomAnchor.constraint(equalTo: artworkContainer.bottomAnchor),
            artworkImageView.leadingAnchor.constraint(equalTo: artworkContainer.leadingAnchor),
            artworkImageView.trailingAnchor.constraint(equalTo: artworkContainer.trailingAnchor),
            
            overlayView.topAnchor.constraint(equalTo: artworkContainer.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: artworkContainer.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: artworkContainer.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: artworkContainer.trailingAnchor),
            
            playImageView.centerXAnchor.constraint(equalTo: artworkContainer.centerXAnchor),
            playImageView.centerYAnchor.constraint(equalTo: artworkContainer.centerYAnchor),
            playImageView.heightAnchor.constraint(equalToConstant: 24),
            playImageView.widthAnchor.constraint(equalToConstant: 24),
            
            textStackView.leadingAnchor.constraint(equalTo: artworkContainer.trailingAnchor, constant: 16),
            textStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStackView.centerYAnchor.constraint(equalTo: artworkContainer.centerYAnchor),
            textStackView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 10),
            textStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10)
        ])
    }
}
