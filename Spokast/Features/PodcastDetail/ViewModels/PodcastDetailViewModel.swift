//
//  PodcastDetailViewModel.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 09/12/25.
//

import Foundation
import Combine

final class PodcastDetailViewModel {

    // MARK: - Properties
    private let podcast: Podcast
    private let service: APIService
    private let audioService: AudioPlayerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var episodes: [Episode] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var currentPlayingEpisodeId: Int? = nil
    @Published private(set) var isPlayerPaused: Bool = false
    
    // MARK: - Initialization
    init(podcast: Podcast,
         service: APIService,
         audioService: AudioPlayerProtocol = AudioService.shared) {
        self.podcast = podcast
        self.service = service
        self.audioService = audioService
        
        setupAudioObserver()
    }
    
    var title: String { return podcast.collectionName }
    var artist: String { return podcast.artistName }
    var genre: String { return podcast.primaryGenreName ?? "Podcast" }
    var coverImageURL: URL? {
        let urlString = podcast.artworkUrl600 ?? podcast.artworkUrl100
        return URL(string: urlString)
    }
    
    // MARK: - API Methods
    func fetchEpisodes() {
        guard let id = podcast.trackId else {
            self.errorMessage = "Invalid Podcast ID"
            return
        }
        
        Task {
            do {
                let fetchedEpisodes = try await service.fetchEpisodes(for: id)
                await MainActor.run {
                    self.episodes = fetchedEpisodes
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Could not load episodes."
                    print("Error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Audio Methods
    func playEpisode(at index: Int) {
        guard episodes.indices.contains(index) else { return }
        let episode = episodes[index]
        
        guard let urlString = episode.previewUrl, let url = URL(string: urlString) else {
            self.errorMessage = "Audio preview not available."
            return
        }
        audioService.toggle(url: url)
    }
    
    // MARK: - Private Setup
    private func setupAudioObserver() {
        audioService.playerState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                self.handleAudioStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func handleAudioStateChange(_ state: AudioPlayerState) {
        switch state {
        case .stopped:
            self.currentPlayingEpisodeId = nil
            self.isPlayerPaused = false
            
        case .playing(let url):
            self.isPlayerPaused = false
            if let episode = self.episodes.first(where: { $0.previewUrl == url.absoluteString }) {
                self.currentPlayingEpisodeId = episode.trackId
            }
            
        case .paused(let url):
            self.isPlayerPaused = true
            if let episode = self.episodes.first(where: { $0.previewUrl == url.absoluteString }) {
                self.currentPlayingEpisodeId = episode.trackId
            }
        }
    }
}
