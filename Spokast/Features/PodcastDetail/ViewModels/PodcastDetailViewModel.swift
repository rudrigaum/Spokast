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
    private let audioPlayerService: AudioPlayerServiceProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Outputs
    @Published private(set) var episodes: [Episode] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var currentPlayingEpisodeId: Int? = nil
    @Published private(set) var isPlayerPaused: Bool = false
    @Published private(set) var isFavorite: Bool = false
    @Published var isPlaying: Bool = false
    @Published var currentPlayingID: Int?
    
    // MARK: - Initialization
    init(podcast: Podcast,
         service: APIService,
         favoritesRepository: FavoritesRepositoryProtocol,
         audioPlayerService: AudioPlayerServiceProtocol = AudioPlayerService.shared) {
        self.podcast = podcast
        self.service = service
        self.favoritesRepository = favoritesRepository
        self.audioPlayerService = audioPlayerService
        
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
        audioPlayerService.play(episode: episode, from: podcast)
    }
    
    func didTapPlay(episode: Episode) {
        audioPlayerService.play(episode: episode, from: podcast)
    }
    
    // MARK: - Private Setup & Helpers
    private func setupAudioObserver() {
        audioPlayerService.playerStatePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPlaying, on: self)
            .store(in: &cancellables)
        
        audioPlayerService.currentEpisodePublisher
            .receive(on: DispatchQueue.main)
            .map { $0?.id }
            .assign(to: \.currentPlayingID, on: self)
            .store(in: &cancellables)
    }
    
    private func makeRepresentativeEpisode() -> Episode {
        return Episode(
            trackId: 0,
            trackName: "Podcast Info",
            description: nil,
            releaseDate: Date(),
            trackTimeMillis: 0,
            previewUrl: nil,
            episodeUrl: nil,
            artworkUrl160: podcast.artworkUrl100,
            collectionName: podcast.collectionName,
            collectionId: podcast.trackId ?? 0,
            artworkUrl600: podcast.artworkUrl600
        )
    }
}
