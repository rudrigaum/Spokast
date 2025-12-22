//
//  PodcastDetailViewController.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 19/12/25.
//

import Foundation
import UIKit
import Kingfisher
import Combine

final class PodcastDetailViewController: UIViewController {

    // MARK: - Properties
    private let viewModel: PodcastDetailViewModel
    private var customView: PodcastDetailView?
    private var cancellables = Set<AnyCancellable>()

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
        customView?.tableView.dataSource = self
        customView?.tableView.delegate = self
        setupConfiguration()
        setupBindings()
        viewModel.fetchEpisodes()
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
    
    // MARK: - Bindings
    private func setupBindings() {
        viewModel.$episodes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] episodes in
                guard let self = self else { return }
                
                if !episodes.isEmpty {
                    print("🚀 SUCESSO! Recebemos \(episodes.count) episódios.")
                    self.customView?.tableView.reloadData()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let _ = self else { return }
                print("❌ ERRO: \(message)")
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest(viewModel.$currentPlayingEpisodeId, viewModel.$isPlayerPaused)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (playingId, isPaused) in
                guard let self = self else { return }
                self.updateVisibleCells(playingId: playingId, isPaused: isPaused)
            }
            .store(in: &cancellables)
    }
    
    private func updateVisibleCells(playingId: Int?, isPaused: Bool) {
        guard let visibleRows = customView?.tableView.indexPathsForVisibleRows else { return }
        
        for indexPath in visibleRows {
            guard let cell = customView?.tableView.cellForRow(at: indexPath) as? EpisodeCell else { continue }
            let episode = viewModel.episodes[indexPath.row]
            
            if episode.trackId == playingId {
                cell.updatePlaybackState(isPlaying: !isPaused)
            } else {
                cell.updatePlaybackState(isPlaying: false)
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension PodcastDetailViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.episodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: EpisodeCell.reuseIdentifier, for: indexPath) as? EpisodeCell else {
            fatalError("Could not dequeue EpisodeCell.")
        }
        
        let episode = viewModel.episodes[indexPath.row]
        cell.configure(with: episode)
        
        if let playingId = viewModel.currentPlayingEpisodeId, playingId == episode.trackId {
            let isPlaying = !viewModel.isPlayerPaused
            cell.updatePlaybackState(isPlaying: isPlaying)
        } else {
            cell.updatePlaybackState(isPlaying: false)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension PodcastDetailViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.playEpisode(at: indexPath.row)
    }
}
