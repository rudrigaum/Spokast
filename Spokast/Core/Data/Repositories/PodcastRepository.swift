//
//  PodcastRepository.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 12/01/26.
//

import Foundation

protocol PodcastRepositoryProtocol {
    func fetchEpisodes(for podcastId: Int) async throws -> [Episode]
}

final class PodcastRepository: PodcastRepositoryProtocol {
    
    // MARK: - Dependencies
    private let apiService: APIServiceProtocol
    private let rssParser: RSSParserServiceProtocol
    
    // MARK: - Initialization
    init(apiService: APIServiceProtocol = APIService(),rssParser: RSSParserServiceProtocol = RSSParserService()) {
        self.apiService = apiService
        self.rssParser = rssParser
    }
    
    // MARK: - Public API
    func fetchEpisodes(for podcastId: Int) async throws -> [Episode] {
        let podcast = try await fetchPodcastDetails(id: podcastId)
        
        guard let feedUrlString = podcast.feedUrl,
              let feedUrl = URL(string: feedUrlString) else {
            throw URLError(.resourceUnavailable)
        }
        
        let episodes = try await rssParser.parse(feedURL: feedUrl)
        
        let enrichedEpisodes = episodes.map { episode -> Episode in
            let mutableEpisode = episode
            if mutableEpisode.artworkUrl600 == nil {
                return Episode(
                    trackId: episode.trackId,
                    trackName: episode.trackName,
                    description: episode.description,
                    releaseDate: episode.releaseDate,
                    trackTimeMillis: episode.trackTimeMillis,
                    previewUrl: episode.previewUrl,
                    episodeUrl: episode.episodeUrl,
                    artworkUrl160: podcast.artworkUrl600,
                    collectionName: podcast.collectionName,
                    collectionId: podcastId,
                    artworkUrl600: episode.artworkUrl600 ?? podcast.artworkUrl600,
                    artistName: podcast.artistName
                )
            }
            return mutableEpisode
        }
        
        return enrichedEpisodes
    }
    
    // MARK: - Private Helpers
    private func fetchPodcastDetails(id: Int) async throws -> Podcast {
        return try await apiService.fetchPodcastDetails(id: id)
    }
}
