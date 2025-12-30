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
    init(service: AudioPlayerService = .shared) {
        self.service = service
        setupBindings()
    }
    
    // MARK: - User Intent
    func togglePlayPause() {
        service.togglePlayPause()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        service.playerStatePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPlaying, on: self)
            .store(in: &cancellables)
        
        Publishers.CombineLatest(service.currentEpisodePublisher, service.currentPodcastPublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] episode, podcast in
                guard let self = self else { return }
                
                if let episode = episode, let podcast = podcast {
                    self.isVisible = true
                    self.episodeTitle = episode.trackName
                    self.podcastTitle = podcast.collectionName
                    
                    let urlString = episode.artworkUrl600 ?? podcast.artworkUrl600 ?? podcast.artworkUrl100
                    self.imageURL = URL(string: urlString)
                    
                } else {
                    self.isVisible = false
                }
            }
            .store(in: &cancellables)
    }
}
