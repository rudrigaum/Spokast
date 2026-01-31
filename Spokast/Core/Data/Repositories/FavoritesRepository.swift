//
//  FavoritesRepository.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 25/12/25.
//

import Foundation
import SwiftData

// MARK: - Protocol
@MainActor
protocol FavoritesRepositoryProtocol {
    func togglePodcastSubscription(for podcast: Podcast) throws -> Bool
    func isPodcastFollowed(id: Int) -> Bool
    func fetchFollowedPodcasts() -> [SavedPodcast]
    
    // TODO: Legacy / To Migrate (SavedEpisode)
    func toggleEpisodeLike(for episode: Episode) throws -> Bool
    func isEpisodeLiked(id: Int) -> Bool
    // func fetchLikedEpisodes() -> [FavoriteEpisode]
}

// MARK: - Implementation
@MainActor
final class FavoritesRepository: FavoritesRepositoryProtocol {
    private let context: ModelContext
    
    init(context: ModelContext? = nil) {
        self.context = context ?? DatabaseService.shared.context
    }
    
    // MARK: - PODCASTS
    func togglePodcastSubscription(for podcast: Podcast) throws -> Bool {
        let idToCheck = podcast.collectionId ?? podcast.trackId ?? 0
        
        if isPodcastFollowed(id: idToCheck) {
            try removePodcast(id: idToCheck)
            return false
        } else {
            try savePodcast(from: podcast)
            return true
        }
    }
    
    func isPodcastFollowed(id: Int) -> Bool {
        let idToCheck = id
        var descriptor = FetchDescriptor<SavedPodcast>(
            predicate: #Predicate { $0.collectionId == idToCheck }
        )
        descriptor.fetchLimit = 1
        
        do {
            let count = try context.fetchCount(descriptor)
            return count > 0
        } catch {
            print("❌ Error checking if podcast is followed: \(error)")
            return false
        }
    }
    
    func fetchFollowedPodcasts() -> [SavedPodcast] {
        let descriptor = FetchDescriptor<SavedPodcast>(
            sortBy: [SortDescriptor(\.collectionName)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ Error fetching followed podcasts: \(error)")
            return []
        }
    }
    
    private func savePodcast(from apiPodcast: Podcast) throws {
        let savedPodcast = SavedPodcast(from: apiPodcast)
        
        context.insert(savedPodcast)
        try context.save()
    }
    
    private func removePodcast(id: Int) throws {
        let idToDelete = id
        let descriptor = FetchDescriptor<SavedPodcast>(
            predicate: #Predicate { $0.collectionId == idToDelete }
        )
        
        if let podcastToDelete = try context.fetch(descriptor).first {
            context.delete(podcastToDelete)
            try context.save()
        }
    }
    
    // MARK: - EPISODES (Legacy / To Migrate)
    func toggleEpisodeLike(for episode: Episode) throws -> Bool {
        return false
    }
    
    func isEpisodeLiked(id: Int) -> Bool {
        return false
    }
}
