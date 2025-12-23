//
//  PlayerView.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 22/12/25.
//

import Foundation
import UIKit

final class PlayerView: UIView {

    // MARK: - UI Components
    private let grabberView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray3
        view.layer.cornerRadius = 3
        return view
    }()

    let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()
    
    private let coverContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 10)
        view.layer.shadowRadius = 10
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 2
        label.text = "Episode Title"
        return label
    }()

    private let artistLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.textColor = .systemPink
        label.textAlignment = .center
        label.text = "Podcast Name"
        return label
    }()
    
    let progressSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.tintColor = .systemPurple
        slider.thumbTintColor = .systemPurple
        return slider
    }()
    
    let currentTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = "00:00"
        return label
    }()
    
    let totalTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = "--:--"
        return label
    }()
    
    private lazy var timeStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [currentTimeLabel, UIView(), totalTimeLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fill
        return stack
    }()

    let playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 44, weight: .bold)
        button.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .label
        return button
    }()
    
    let forwardButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        button.setImage(UIImage(systemName: "goforward.30", withConfiguration: config), for: .normal)
        button.tintColor = .label
        return button
    }()
    
    let rewindButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        button.setImage(UIImage(systemName: "gobackward.15", withConfiguration: config), for: .normal)
        button.tintColor = .label
        return button
    }()
    
    private lazy var controlsStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [rewindButton, playPauseButton, forwardButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalCentering
        stack.spacing = 40
        return stack
    }()

    private lazy var mainStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            coverContainerView,
            titleLabel,
            artistLabel,
            progressSlider,
            timeStackView,
            controlsStackView
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .fill
        return stack
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration Public API
    func configure(title: String, artist: String) {
        titleLabel.text = title
        artistLabel.text = artist
    }
    
    func updatePlayButtonState(isPlaying: Bool) {
        let config = UIImage.SymbolConfiguration(pointSize: 44, weight: .bold)
        let iconName = isPlaying ? "pause.circle.fill" : "play.circle.fill"
        playPauseButton.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
    }

    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .systemBackground
        
        addSubview(grabberView)
        coverContainerView.addSubview(coverImageView)
        addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            grabberView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            grabberView.centerXAnchor.constraint(equalTo: centerXAnchor),
            grabberView.widthAnchor.constraint(equalToConstant: 40),
            grabberView.heightAnchor.constraint(equalToConstant: 6),
            
            coverContainerView.heightAnchor.constraint(equalTo: coverContainerView.widthAnchor),
            
            coverImageView.topAnchor.constraint(equalTo: coverContainerView.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: coverContainerView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: coverContainerView.trailingAnchor),
            coverImageView.bottomAnchor.constraint(equalTo: coverContainerView.bottomAnchor),
            
            mainStackView.topAnchor.constraint(equalTo: grabberView.bottomAnchor, constant: 32),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            mainStackView.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }
}
