//
//  LibrarySyncService.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 27/01/26.
//

import Foundation
import SwiftData

@MainActor
protocol LibrarySyncServiceProtocol {
    func syncMissingMetadata() async throws -> Int
}

@MainActor
final class LibrarySyncService: LibrarySyncServiceProtocol {
    
    // MARK: - Dependencies
    private let context: ModelContext
    private let podcastService: PodcastServiceProtocol
    
    // MARK: - Init
    init(
        context: ModelContext? = nil,
        podcastService: PodcastServiceProtocol? = nil
    ) {
        self.context = context ?? DatabaseService.shared.context
        self.podcastService = podcastService ?? PodcastService()
    }
    
    // MARK: - Methods
    func syncMissingMetadata() async throws -> Int {
        let descriptor = FetchDescriptor<SavedPodcast>(
            predicate: #Predicate { $0.artworkUrl600 == nil }
        )
        
        let incompletePodcasts = try context.fetch(descriptor)
        
        guard !incompletePodcasts.isEmpty else { return 0 }
    
        var targets: [Int: String] = [:]
        for podcast in incompletePodcasts {
            if let feedUrl = podcast.feedUrl {
                targets[podcast.collectionId] = feedUrl
            }
        }
        
        let updates = await fetchMetadataInParallel(targets: targets)
        var updatedCount = 0
        
        for podcast in incompletePodcasts {
            if let apiData = updates[podcast.collectionId] {
                applyUpdate(to: podcast, with: apiData)
                updatedCount += 1
            }
        }
        
        if updatedCount > 0 {
            try context.save()
        }
        
        return updatedCount
    }
    
    // MARK: - Private Helpers
    nonisolated private func fetchMetadataInParallel(targets: [Int: String]) async -> [Int: Podcast] {
        
        return await withTaskGroup(of: (Int, Podcast?).self) { group in
            
            for (id, feedUrl) in targets {
                group.addTask {
                    let service = PodcastService()
                    
                    do {
                        let podcast = try await service.fetchPodcast(byFeedUrl: feedUrl)
                        return (id, podcast)
                    } catch {
                        print("⚠️ Sync Warning: Failed to fetch metadata for \(feedUrl): \(error)")
                        return (id, nil)
                    }
                }
            }
            
            var results: [Int: Podcast] = [:]
            for await (id, podcastOrNil) in group {
                if let podcast = podcastOrNil {
                    results[id] = podcast
                }
            }
            return results
        }
    }
    
    private func applyUpdate(to local: SavedPodcast, with remote: Podcast) {
        local.artistName = remote.artistName
        local.collectionName = remote.collectionName
        local.artworkUrl600 = remote.artworkUrl600
        local.primaryGenreName = remote.primaryGenreName
        
        if let realTrackId = remote.trackId, realTrackId != 0 {
            local.collectionId = realTrackId
        }
    }
}
