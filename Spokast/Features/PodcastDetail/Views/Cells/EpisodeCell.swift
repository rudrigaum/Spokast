//
//  EpisodeCell.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 20/12/25.
//

import Foundation
import UIKit

final class EpisodeCell: UITableViewCell {

    static let reuseIdentifier = "EpisodeCell"
    
    // MARK: - Actions
    var onPlayTap: (() -> Void)?
    
    // MARK: - UI Components
    private lazy var playIconContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemPurple.withAlphaComponent(0.1)
        view.layer.cornerRadius = 20
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private let playImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "play.fill")
        imageView.tintColor = .systemPurple
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
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
    
    // MARK: - Configuration
    func configure(with episode: Episode, isPlaying: Bool) {
        titleLabel.text = episode.trackName
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let dateString = dateFormatter.string(from: episode.releaseDate)
        let durationText = formatDuration(millis: episode.trackTimeMillis)
        
        descriptionLabel.text = "\(dateString) • \(durationText)"
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
        
        playIconContainer.backgroundColor = isPlaying ? .systemPurple.withAlphaComponent(0.3) : .systemPurple.withAlphaComponent(0.1)
    }
    
    // MARK: - Gestures
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPlayContainer))
        playIconContainer.addGestureRecognizer(tapGesture)
    }
    
    @objc private func didTapPlayContainer() {
        UIView.animate(withDuration: 0.1, animations: {
            self.playIconContainer.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.playIconContainer.transform = .identity
            }
        }
        onPlayTap?()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .systemBackground
        selectionStyle = .default
        
        contentView.addSubview(playIconContainer)
        playIconContainer.addSubview(playImageView)
        contentView.addSubview(textStackView)
        
        NSLayoutConstraint.activate([
            playIconContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            playIconContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playIconContainer.heightAnchor.constraint(equalToConstant: 40),
            playIconContainer.widthAnchor.constraint(equalToConstant: 40),
            
            playImageView.centerXAnchor.constraint(equalTo: playIconContainer.centerXAnchor),
            playImageView.centerYAnchor.constraint(equalTo: playIconContainer.centerYAnchor),
            playImageView.heightAnchor.constraint(equalToConstant: 16),
            playImageView.widthAnchor.constraint(equalToConstant: 16),
            
            textStackView.leadingAnchor.constraint(equalTo: playIconContainer.trailingAnchor, constant: 16),
            textStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            textStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
}
