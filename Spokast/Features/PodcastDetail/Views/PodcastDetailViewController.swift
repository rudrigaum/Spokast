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

protocol PodcastDetailCoordinatorDelegate: AnyObject {
    var navigationController: UINavigationController { get }
    func showEpisodeDetails(_ episode: Episode, from podcast: Podcast)
}

final class PodcastDetailViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: PodcastDetailViewModel
    
    private var customView: PodcastDetailView? {
        return self.view as? PodcastDetailView
    }
    
    private var cancellables = Set<AnyCancellable>()
    weak var coordinator: PodcastDetailCoordinatorDelegate?
    
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
        self.view = PodcastDetailView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        customView?.tableView.dataSource = self
        customView?.tableView.delegate = self
        
        setupConfiguration()
        setupActions()
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
    
    // MARK: - Actions Setup
    private func setupActions() {
        customView?.subscribeButton.addTarget(self, action: #selector(didTapSubscribe), for: .touchUpInside)
    }
    
    @objc private func didTapSubscribe() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        viewModel.didTapSubscribe()
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        bindEpisodes()
        bindErrors()
        bindPlayerState()
        bindSubscriptionState()
    }
    
    private func bindEpisodes() {
        viewModel.$episodes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] episodes in
                guard let self = self else { return }
                if !episodes.isEmpty {
                    self.customView?.tableView.reloadData()
                }
            }
            .store(in: &cancellables)
    }
    
    private func bindErrors() {
        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let _ = self else { return }
                print("❌ ERRO: \(message)")
            }
            .store(in: &cancellables)
    }
    
    private func bindPlayerState() {
        Publishers.CombineLatest(viewModel.$currentPlayingID, viewModel.$isPlaying)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (playingId, isPlaying) in
                guard let self = self else { return }
                
                self.customView?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    private func bindSubscriptionState() {
        viewModel.$isFavorite
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFavorite in
                self?.customView?.updateSubscribeButton(isSubscribed: isFavorite)
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell", for: indexPath) as? EpisodeCell else {
            return UITableViewCell()
        }
        
        let episode = viewModel.episodes[indexPath.row]
        let isPlayingThisEpisode = viewModel.isPlaying && (viewModel.currentPlayingID == episode.id)

        cell.configure(with: episode, isPlaying: isPlayingThisEpisode)
        cell.onPlayTap = { [weak self] in
            self?.viewModel.playEpisode(at: indexPath.row)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension PodcastDetailViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let episode = viewModel.episodes[indexPath.row]
        coordinator?.showEpisodeDetails(episode, from: viewModel.podcast)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 300
    }
}

extension PodcastDetailCoordinatorDelegate {
    
    func showEpisodeDetails(_ episode: Episode, from podcast: Podcast) {
        let viewModel = EpisodeDetailViewModel(episode: episode, podcast: podcast)
        let episodeDetailVC = EpisodeDetailViewController(viewModel: viewModel)
        
        navigationController.pushViewController(episodeDetailVC, animated: true)
    }
}
