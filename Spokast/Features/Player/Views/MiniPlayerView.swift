//
//  MiniPlayerView.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 29/12/25.
//

import Foundation
import UIKit
import Combine
import Kingfisher

final class MiniPlayerView: UIView {
    
    // MARK: - Properties
    private let viewModel: MiniPlayerViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    private let blurView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .systemChromeMaterial)
        let view = UIVisualEffectView(effect: effect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 8
        iv.clipsToBounds = true
        iv.backgroundColor = .secondarySystemBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var playPauseButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        btn.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .label
        btn.addTarget(self, action: #selector(didTapPlayPause), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .bar)
        pv.trackTintColor = .clear
        pv.progressTintColor = .systemPurple
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator.withAlphaComponent(0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Init
    init(viewModel: MiniPlayerViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupLayout()
        setupBindings()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    
    @objc private func didTapPlayPause() {
        viewModel.togglePlayPause()
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        bindLabels()
        bindImages()
        bindControls()
    }
    
    private func bindLabels() {
        viewModel.$episodeTitle
            .map { $0 as String? }
            .assign(to: \.text, on: titleLabel)
            .store(in: &cancellables)
        
        viewModel.$podcastTitle
            .map { $0 as String? }
            .assign(to: \.text, on: subtitleLabel)
            .store(in: &cancellables)
    }
    
    private func bindImages() {
        viewModel.$imageURL
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in
                self?.imageView.kf.setImage(with: url, placeholder: UIImage(systemName: "music.note"))
            }
            .store(in: &cancellables)
    }
    
    private func bindControls() {
        viewModel.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaying in
                let iconName = isPlaying ? "pause.fill" : "play.fill"
                let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
                self?.playPauseButton.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Layout
    private func setupLayout() {
        addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        addSubview(progressView)
        addSubview(separatorView)
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(playPauseButton)
        
        NSLayoutConstraint.activate([
            separatorView.topAnchor.constraint(equalTo: topAnchor),
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),
            
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor), // Quadrada
            
            playPauseButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playPauseButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            playPauseButton.widthAnchor.constraint(equalToConstant: 44),
            playPauseButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: playPauseButton.leadingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 4),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            
            progressView.topAnchor.constraint(equalTo: topAnchor),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])
    }
}
