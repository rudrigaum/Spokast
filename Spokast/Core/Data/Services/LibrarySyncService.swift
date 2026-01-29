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
    
    // MARK: - Configuration
    private let batchSize = 1
    private let delayBetweenBatches: UInt64 = 1_500_000_000
    
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
        
        guard !incompletePodcasts.isEmpty else {
            return 0
        }
        
        var targets: [Int: (url: String, title: String)] = [:]
        for podcast in incompletePodcasts {
            if let feedUrl = podcast.feedUrl {
                let cleanUrl = feedUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanTitle = podcast.collectionName
                    .replacingOccurrences(of: "\n", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                targets[podcast.collectionId] = (cleanUrl, cleanTitle)
            }
        }
        
        let updates = await fetchMetadataInBatches(targets: targets)
        
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
    nonisolated private func fetchMetadataInBatches(targets: [Int: (url: String, title: String)]) async -> [Int: Podcast] {
        var allResults: [Int: Podcast] = [:]
        let targetArray = Array(targets)
        let total = targetArray.count
        
        for i in stride(from: 0, to: total, by: batchSize) {
            let end = min(i + batchSize, total)
            let batch = Array(targetArray[i..<end])
            let batchResults = await processBatch(batch)
            
            for (id, podcast) in batchResults {
                allResults[id] = podcast
            }
            
            if end < total {
                try? await Task.sleep(nanoseconds: delayBetweenBatches)
            }
        }
        
        return allResults
    }
    
    nonisolated private func processBatch(_ batch: [(key: Int, value: (url: String, title: String))]) async -> [Int: Podcast] {
            return await withTaskGroup(of: (Int, Podcast?).self) { group in
                
                for (id, data) in batch {
                    group.addTask {
                        let service = PodcastService()
                        
                        do {
                            if let p = try await service.fetchPodcast(byFeedUrl: data.url) {
                                return (id, p)
                            }
                        } catch {
            
                        }
                        
                        let searchTitle = data.title
                            .replacingOccurrences(of: "Podcast", with: "", options: .caseInsensitive)
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if !searchTitle.isEmpty {
                            do {
                                let results = try await service.fetchPodcasts(searchTerm: searchTitle, limit: 1)
                                if let p = results.first {
                                    return (id, p)
                                }
                            } catch {
                
                            }
                        }
                        
                        return (id, nil)
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
        if let newArtist = remote.artistName {
            local.artistName = newArtist
        }
        
        if let newTitle = remote.collectionName {
            local.collectionName = newTitle
        }
        
        local.artworkUrl600 = remote.artworkUrl600 ?? remote.artworkUrl100
        local.primaryGenreName = remote.primaryGenreName
        
        if remote.id != 0 {
            local.collectionId = remote.id
        }
    }
}
