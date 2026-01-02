//
//  EpisodeDetailViewController.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 01/01/26.
//

import Foundation
import UIKit

final class EpisodeDetailViewController: UIViewController {

    // MARK: - Properties
    private let viewModel: EpisodeDetailViewModel
    
    private var customView: EpisodeDetailView? {
        return view as? EpisodeDetailView
    }

    // MARK: - Init
    init(viewModel: EpisodeDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.title = "Details"
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func loadView() {
        self.view = EpisodeDetailView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        setupConfiguration()
        setupActions()
    }
    
    // MARK: - Setup
    private func setupConfiguration() {
        customView?.configure(
            with: viewModel.getEpisode(),
            podcast: viewModel.getPodcast(),
            podcastImageURL: viewModel.imageURL
        )
    }
    
    private func setupActions() {
        customView?.onPlayTap = { [weak self] in
            self?.playEpisode()
        }
    }
    
    private func playEpisode() {
        AudioPlayerService.shared.play(
            episode: viewModel.getEpisode(),
            from: viewModel.getPodcast()
        )
    }
}
