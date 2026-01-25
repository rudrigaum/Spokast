//
//  SwiftDataPlaybackPersistence.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 23/01/26.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataPlaybackPersistence: PlaybackPersistenceProtocol {
    
    private let context: ModelContext
    
    init() {
        self.context = DatabaseService.shared.context
    }
    
    // MARK: - Save (Upsert Logic)
    func save(checkpoint: PlaybackCheckpoint) throws {
        let episodeId = String(checkpoint.episode.trackId)
        
        let encoder = JSONEncoder()
        let episodeData = try? encoder.encode(checkpoint.episode)
        
        let descriptor = FetchDescriptor<EpisodeProgress>(
            predicate: #Predicate { $0.episodeId == episodeId }
        )
        
        let existingProgress = try context.fetch(descriptor).first
        
        if let progress = existingProgress {
            progress.currentTime = checkpoint.timestamp
            progress.lastPlayedAt = checkpoint.savedAt
            progress.episodeData = episodeData
        } else {
            let newProgress = EpisodeProgress(
                episodeId: episodeId,
                podcastId: String(checkpoint.episode.collectionId),
                currentTime: checkpoint.timestamp,
                duration: checkpoint.episode.durationInSeconds,
                lastPlayedAt: checkpoint.savedAt,
                episodeTitle: checkpoint.episode.trackName,
                podcastTitle: checkpoint.podcastTitle,
                podcastArtWorkURLString: checkpoint.podcastArtWorkURL?.absoluteString,
                episodeData: episodeData
            )
            context.insert(newProgress)
        }
    }
    
    // MARK: - Load Last Played
    func load() -> PlaybackCheckpoint? {
        var descriptor = FetchDescriptor<EpisodeProgress>(
            sortBy: [SortDescriptor(\.lastPlayedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        
        guard let progress = try? context.fetch(descriptor).first,
              let data = progress.episodeData else {
            return nil
        }
        
        let decoder = JSONDecoder()
        guard let episode = try? decoder.decode(Episode.self, from: data) else {
            return nil
        }
        
        return PlaybackCheckpoint(
            episode: episode,
            podcastTitle: progress.podcastTitle,
            podcastArtWorkURL: URL(string: progress.podcastArtWorkURLString ?? ""),
            timestamp: progress.currentTime,
            savedAt: progress.lastPlayedAt
        )
    }
    
    func clear() {
        try? context.delete(model: EpisodeProgress.self)
    }
}
