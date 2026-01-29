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

@MainActor
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
    
    private lazy var searchController: UISearchController = {
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search episodes"
        search.hidesNavigationBarDuringPresentation = false 
        return search
    }()
    
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
        setupSearchController()
        
        viewModel.fetchEpisodes()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.isMovingFromParent {
            KingfisherManager.shared.cache.clearMemoryCache()
        }
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
    
    private func setupSearchController() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
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
        bindDownloads()
    }
    
    private func bindEpisodes() {
        viewModel.$episodes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] episodes in
                self?.customView?.tableView.reloadData()
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
        viewModel.$currentPlayingID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] playingId in
                self?.updateVisibleCells(playingId: playingId, isPlaying: self?.viewModel.isPlaying ?? false)
            }
            .store(in: &cancellables)
        
        viewModel.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaying in
                self?.updateVisibleCells(playingId: self?.viewModel.currentPlayingID, isPlaying: isPlaying)
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
    
    private func bindDownloads() {
        viewModel.$onDownloadsUpdate
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.updateVisibleCellsDownloadState()
            }
            .store(in: &cancellables)
    }
    
    private func updateVisibleCellsDownloadState() {
        guard let visiblePaths = customView?.tableView.indexPathsForVisibleRows else { return }
        
        for indexPath in visiblePaths {
            guard indexPath.row < viewModel.episodes.count else { continue }
            
            let episode = viewModel.episodes[indexPath.row]
            let status = viewModel.getDownloadStatus(for: episode)
            
            if let cell = customView?.tableView.cellForRow(at: indexPath) as? EpisodeCell {
                cell.downloadButton.updateState(status)
            }
        }
    }
    
    
    
    private func updateVisibleCells(playingId: Int?, isPlaying: Bool) {
        guard let visibleRows = customView?.tableView.indexPathsForVisibleRows else { return }
        
        for indexPath in visibleRows {
            guard let cell = customView?.tableView.cellForRow(at: indexPath) as? EpisodeCell else { continue }
            
            if indexPath.row < viewModel.episodes.count {
                let episode = viewModel.episodes[indexPath.row]
                
                if episode.id == playingId {
                    cell.updatePlaybackState(isPlaying: isPlaying)
                } else {
                    cell.updatePlaybackState(isPlaying: false)
                }
            }
        }
    }
    
    // MARK: - Download Actions
    private func handleDownloadTap(for episode: Episode) {
        let status = viewModel.getDownloadStatus(for: episode)
        
        if case .downloaded = status {
            let cell = getCell(for: episode)
            let sourceButton = cell?.downloadButton
            
            presentDeleteConfirmation(for: episode, sourceView: sourceButton) { [weak self] in
                self?.viewModel.deleteEpisode(episode)
            }
            
        } else {
            viewModel.toggleDownload(for: episode)
            updateVisibleCellsDownloadState()
        }
    }
    
    private func getCell(for episode: Episode) -> EpisodeCell? {
        guard let index = viewModel.episodes.firstIndex(where: { $0.id == episode.id }) else { return nil }
        let indexPath = IndexPath(row: index, section: 0)
        return customView?.tableView.cellForRow(at: indexPath) as? EpisodeCell
    }
}

// MARK: - UITableViewDataSource
extension PodcastDetailViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.episodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: EpisodeCell.reuseIdentifier, for: indexPath) as? EpisodeCell else {
            return UITableViewCell()
        }
        
        let episode = viewModel.episodes[indexPath.row]
        let podcastArtString = viewModel.podcast.artworkUrl600 ?? viewModel.podcast.artworkUrl100
        let podcastArtURL = URL(string: podcastArtString ?? "")
        let isPlayingThisEpisode = viewModel.isPlaying && (viewModel.currentPlayingID == episode.id)
        let downloadStatus = viewModel.getDownloadStatus(for: episode)
        
        cell.configure(
            with: episode,
            downloadStatus: downloadStatus,
            podcastArtURL: podcastArtURL,
            isPlaying: isPlayingThisEpisode
        )
        
        cell.onPlayTap = { [weak self] in
            self?.viewModel.playEpisode(at: indexPath.row)
        }
        
        cell.didTapDownloadAction = { [weak self] in
            self?.handleDownloadTap(for: episode)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension PodcastDetailViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < viewModel.episodes.count else { return }
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

// MARK: - UISearchResultsUpdating
extension PodcastDetailViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        viewModel.filterEpisodes(with: text)
    }
}
