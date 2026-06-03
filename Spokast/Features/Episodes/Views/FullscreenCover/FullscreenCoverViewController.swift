//
//  FullscreenCoverViewController.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 01/06/26.
//

import Foundation
import UIKit

final class FullscreenCoverViewController: UIViewController {

    // MARK: - Properties
    private let initialImage: UIImage?

    private var customView: FullscreenCoverView? {
        return view as? FullscreenCoverView
    }

    // MARK: - Init
    init(image: UIImage?) {
        self.initialImage = image
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func loadView() {
        self.view = FullscreenCoverView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupConfiguration()
        setupActions()
    }

    // MARK: - Setup
    private func setupConfiguration() {
        customView?.configure(with: initialImage)
    }

    private func setupActions() {
        customView?.onTapDismiss = { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    // MARK: - Public Exposure for Animator
    func getImageView() -> UIImageView? {
        return customView?.coverImageView
    }

    func getCustomView() -> FullscreenCoverView? {
        return customView
    }
}
