//
//  MiniPlayerViewModel.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 29/12/25.
//

import Foundation
import Combine

@MainActor
final class MiniPlayerViewModel {
    
    // MARK: - Dependencies
    private let service: AudioPlayerService
    
    // MARK: - Outputs
    @Published private(set) var episodeTitle: String = ""
    @Published private(set) var podcastTitle: String = ""
    @Published private(set) var imageURL: URL?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var isVisible: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init(service: AudioPlayerService? = nil) {
        self.service = service ?? AudioPlayerService.shared
        setupBindings()
    }
    
    // MARK: - User Intent
    func togglePlayPause() {
        guard let episode = service.currentEpisode,
              let urlString = episode.previewUrl,
              let url = URL(string: urlString) else {
            return
        }
        service.toggle(url: url)
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        bindPlayerState()
        bindEpisodeData()
    }
    
    private func bindPlayerState() {
        service.playerStatePublisher
            .map { state -> Bool in
                if case .playing = state { return true }
                return false
            }
            .assign(to: \.isPlaying, on: self)
            .store(in: &cancellables)
    }
    
    private func bindEpisodeData() {
        service.currentEpisodePublisher
            .sink { [weak self] episode in
                self?.updatePlayerMetadata(with: episode)
            }
            .store(in: &cancellables)
    }
    
    private func updatePlayerMetadata(with episode: Episode?) {
        if let episode = episode {
            self.isVisible = true
            self.episodeTitle = episode.trackName
            self.podcastTitle = episode.collectionName ?? episode.artistName ?? "Podcast"
            self.imageURL = self.service.currentPodcastImageURL
        } else {
            self.isVisible = false
        }
    }
}
