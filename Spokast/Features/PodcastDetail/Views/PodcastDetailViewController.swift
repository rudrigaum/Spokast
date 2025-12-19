//
//  PodcastDetailViewController.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 19/12/25.
//

import Foundation
import UIKit
import Kingfisher

final class PodcastDetailViewController: UIViewController {

    // MARK: - Properties
    private let viewModel: PodcastDetailViewModel
    private var customView: PodcastDetailView?

    // MARK: - Initialization
    init(viewModel: PodcastDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func loadView() {
        self.customView = PodcastDetailView()
        self.view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupConfiguration()
    }
    
    // MARK: - Configuration
    private func setupConfiguration() {
        guard let customView = customView else { return }
        
        customView.configure(with: viewModel)
        
        if let url = viewModel.coverImageURL {
            customView.imageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "photo"),
                options: [
                    .transition(.fade(0.3)),
                    .cacheOriginalImage
                ]
            )
        }
    }
}
