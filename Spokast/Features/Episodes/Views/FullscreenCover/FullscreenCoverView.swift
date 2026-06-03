//
//  FullscreenCoverView.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 01/06/26.
//

import Foundation
import UIKit

final class FullscreenCoverView: UIView {

    // MARK: - Actions
    var onTapDismiss: (() -> Void)?

    // MARK: - UI Components
    private let blurredBackgroundView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemMaterialDark)
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        return view
    }()

    let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        imageView.alpha = 0
        return imageView
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGestures()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods
    func configure(with image: UIImage?) {
        coverImageView.image = image
    }

    func setBlurAlpha(_ alpha: CGFloat) {
        blurredBackgroundView.alpha = alpha
    }

    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear

        addSubview(blurredBackgroundView)
        addSubview(coverImageView)

        NSLayoutConstraint.activate([
            blurredBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            blurredBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            blurredBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurredBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),

            coverImageView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            coverImageView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
            coverImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            coverImageView.heightAnchor.constraint(equalTo: coverImageView.widthAnchor)
        ])
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        coverImageView.addGestureRecognizer(imageTapGesture)
    }

    @objc private func handleTap() {
        onTapDismiss?()
    }
}
