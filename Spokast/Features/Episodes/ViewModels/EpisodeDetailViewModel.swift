//
//  EpisodeDetailViewModel.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 02/01/26.
//

import Foundation

final class EpisodeDetailViewModel {
    
    // MARK: - Properties
    private let episode: Episode
    private let podcast: Podcast
    
    // MARK: - Init
    init(episode: Episode, podcast: Podcast) {
        self.episode = episode
        self.podcast = podcast
    }
    
    // MARK: - Outputs
    var title: String {
        return episode.trackName
    }
    
    var podcastName: String {
        return podcast.artistName ?? "Unknown Artist"
    }
    
    var description: String {
        return episode.description ?? ""
    }
    
    var imageURL: URL? {
        if let urlString = episode.artworkUrl600, let url = URL(string: urlString) {
            return url
        }
        
        if let urlString = episode.artworkUrl160, let url = URL(string: urlString) {
            return url
        }
        
        if let urlString = podcast.artworkUrl600, let url = URL(string: urlString) {
            return url
        }
        
        return URL(string: podcast.artworkUrl100 ?? "")
    }
    
    
    func getEpisode() -> Episode {
        return episode
    }
    
    func getPodcast() -> Podcast {
        return podcast
    }
}
