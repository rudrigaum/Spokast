//
//  Episode.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 19/12/25.
//

import Foundation

struct Episode: Codable, Identifiable {
    var id: Int { trackId }
    let trackId: Int
    let trackName: String
    let description: String?
    let releaseDate: Date
    let trackTimeMillis: Int?
    let previewUrl: String?
    let episodeUrl: String?
    let artworkUrl160: String?
    let collectionName: String?
    let collectionId: Int
    let artworkUrl600: String?
    let artistName: String?
    
    var durationInSeconds: Double {
        guard let millis = trackTimeMillis else { return 0.0 }
        return Double(millis) / 1000.0
    }
    
    var streamUrl: URL? {
        if let urlString = episodeUrl ?? previewUrl {
            return URL(string: urlString)
        }
        return nil
    }
    
    enum CodingKeys: String, CodingKey {
        case trackId
        case trackName
        case description
        case releaseDate
        case trackTimeMillis
        case previewUrl
        case episodeUrl
        case artworkUrl160
        case collectionName
        case collectionId
        case artworkUrl600
        case artistName
    }
}

extension Episode {
    var asPodcast: Podcast {
        return Podcast(
            trackId: collectionId, 
            artistName: artistName ?? "Unknown Artist",
            collectionName: collectionName ?? "Unknown Podcast",
            artworkUrl100: artworkUrl160 ?? "",
            feedUrl: nil,
            artworkUrl600: artworkUrl600,
            primaryGenreName: nil
        )
    }
}
