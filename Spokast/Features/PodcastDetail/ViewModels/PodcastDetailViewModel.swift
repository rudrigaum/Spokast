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
    private let favoritesRepository: FavoritesRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Outputs
    @Published private(set) var episodes: [Episode] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var currentPlayingEpisodeId: Int? = nil
    @Published private(set) var isPlayerPaused: Bool = false
    @Published private(set) var isFavorite: Bool = false
    
    // MARK: - Initialization
    init(podcast: Podcast, service: APIService, audioService: AudioPlayerProtocol = AudioService.shared, favoritesRepository: FavoritesRepositoryProtocol) {
        self.podcast = podcast
        self.service = service
        self.audioService = audioService
        self.favoritesRepository = favoritesRepository
        
        setupAudioObserver()
        checkFavoriteStatus()
    }
    
    // MARK: - Computed Properties
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
    
    // MARK: - Subscription Logic
    func checkFavoriteStatus() {
        guard let id = podcast.trackId else { return }
        isFavorite = favoritesRepository.isPodcastFollowed(id: id)
    }
    
    func didTapSubscribe() {
        let podcastAsEpisode = makeRepresentativeEpisode()
        
        do {
            let newState = try favoritesRepository.togglePodcastSubscription(for: podcastAsEpisode)
            isFavorite = newState
        } catch {
            print("❌ Error toggling subscription: \(error)")
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
    
    // MARK: - Private Setup & Helpers
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
    
    private func makeRepresentativeEpisode() -> Episode {
        return Episode(
            trackId: 0,
            trackName: "Podcast Info",
            description: nil,
            releaseDate: Date(),
            trackTimeMillis: 0,
            previewUrl: nil,
            artworkUrl160: podcast.artworkUrl100,
            collectionName: podcast.collectionName,
            collectionId: podcast.trackId ?? 0,
            artworkUrl600: podcast.artworkUrl600
        )
    }
}
