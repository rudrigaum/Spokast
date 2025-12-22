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
    
    @Published private(set) var episodes: [Episode] = []
    @Published private(set) var errorMessage: String?
    
    // MARK: - Initialization
    init(podcast: Podcast, service: APIService, audioService: AudioPlayerProtocol = AudioService.shared) {
        self.podcast = podcast
        self.service = service
        self.audioService = audioService
    }
    
    // MARK: - Outputs
    var title: String {
        return podcast.collectionName
    }
    
    var artist: String {
        return podcast.artistName
    }
    
    var coverImageURL: URL? {
        let urlString = podcast.artworkUrl600 ?? podcast.artworkUrl100
        return URL(string: urlString)
    }
    
    var genre: String {
        return podcast.primaryGenreName ?? "Podcast"
    }
    
    // MARK: - API Methods
    func fetchEpisodes() {
        Task {
            do {
                let fetchedEpisodes = try await service.fetchEpisodes(for: podcast.trackId ?? 0)
                
                await MainActor.run {
                    self.episodes = fetchedEpisodes
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Could not load episodes. Please try again."
                    print("Error fetching episodes: \(error)")
                }
            }
        }
    }
    
    // MARK: - Audio Methods
    func playEpisode(at index: Int) {
        guard episodes.indices.contains(index) else { return }
        let episode = episodes[index]
        
        guard let urlString = episode.previewUrl, let url = URL(string: urlString) else {
            self.errorMessage = "Sorry, audio preview not available for this episode."
            return
        }
        
        audioService.play(url: url)
    }
}
