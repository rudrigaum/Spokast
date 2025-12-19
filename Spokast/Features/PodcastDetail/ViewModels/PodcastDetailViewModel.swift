//
//  PodcastDetailViewModel.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 09/12/25.
//

import Foundation

final class PodcastDetailViewModel {

    // MARK: - Properties
    private let podcast: Podcast
    
    // MARK: - Initialization
    init(podcast: Podcast) {
        self.podcast = podcast
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
    
    var description: String {
        return "Podcast details and episodes coming soon..."
    }
}
