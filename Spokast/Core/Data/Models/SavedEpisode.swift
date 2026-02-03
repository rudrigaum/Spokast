//
//  SavedEpisode.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 02/02/26.
//

import Foundation
import SwiftData

@Model
final class SavedEpisode {
    
    @Attribute(.unique) var id: Int
    var podcastId: Int
    var title: String
    var duration: TimeInterval
    var releaseDate: Date?
    var streamUrl: String?
    var artworkUrl: String?
    
    // MARK: - Playback State (Core Feature)
    var isPlayed: Bool = false
    var playbackPosition: TimeInterval = 0.0
    var lastPlayedAt: Date?
    
    // MARK: - Init
    init(
        id: Int,
        podcastId: Int,
        title: String,
        duration: TimeInterval,
        releaseDate: Date? = nil,
        streamUrl: String? = nil,
        artworkUrl: String? = nil,
        isPlayed: Bool = false,
        playbackPosition: TimeInterval = 0.0
    ) {
        self.id = id
        self.podcastId = podcastId
        self.title = title
        self.duration = duration
        self.releaseDate = releaseDate
        self.streamUrl = streamUrl
        self.artworkUrl = artworkUrl
        self.isPlayed = isPlayed
        self.playbackPosition = playbackPosition
        self.lastPlayedAt = isPlayed ? Date() : nil
    }
}

// MARK: - Domain Mapping
extension SavedEpisode {
    convenience init(from episode: Episode) {
        self.init(
            id: episode.trackId,
            podcastId: episode.collectionId,
            title: episode.trackName,
            duration: Double(episode.durationInSeconds),
            releaseDate: episode.releaseDate,
            streamUrl: episode.streamUrl?.absoluteString,
            artworkUrl: episode.artworkUrl160,
            isPlayed: false,
            playbackPosition: 0.0
        )
    }
}
