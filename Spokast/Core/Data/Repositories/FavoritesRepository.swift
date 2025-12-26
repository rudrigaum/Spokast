//
//  FavoritesRepository.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 25/12/25.
//

import Foundation
import CoreData

// MARK: - Protocol
protocol FavoritesRepositoryProtocol {
    func togglePodcastSubscription(for episode: Episode) throws -> Bool
    func isPodcastFollowed(id: Int) -> Bool
    func fetchFollowedPodcasts() -> [FavoritePodcast]
    func toggleEpisodeLike(for episode: Episode) throws -> Bool
    func isEpisodeLiked(id: Int) -> Bool
    func fetchLikedEpisodes() -> [FavoriteEpisode]
}

// MARK: - Implementation
final class FavoritesRepository: FavoritesRepositoryProtocol {
    
    private let context = CoreDataService.shared.viewContext
    
    // MARK: - PODCASTS
    func togglePodcastSubscription(for episode: Episode) throws -> Bool {
        let podcastId = episode.collectionId
        
        if isPodcastFollowed(id: podcastId) {
            try removePodcast(id: Int64(podcastId))
            return false
        } else {
            try savePodcast(from: episode)
            return true
        }
    }
    
    func isPodcastFollowed(id: Int) -> Bool {
        let request: NSFetchRequest<FavoritePodcast> = FavoritePodcast.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", Int64(id))
        request.fetchLimit = 1
        return (try? context.count(for: request)) ?? 0 > 0
    }
    
    func fetchFollowedPodcasts() -> [FavoritePodcast] {
        let request: NSFetchRequest<FavoritePodcast> = FavoritePodcast.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Error fetching followed podcasts: \(error)")
            return []
        }
    }
    
    private func savePodcast(from episode: Episode) throws {
        let podcast = FavoritePodcast(context: context)
        podcast.id = Int64(episode.collectionId)
        podcast.title = episode.collectionName ?? "Unknown Podcast"
        podcast.coverUrl = episode.artworkUrl600 ?? episode.artworkUrl160
        podcast.author = "Artist"
        podcast.createdAt = Date()
        try context.save()
    }
    
    private func removePodcast(id: Int64) throws {
        let request: NSFetchRequest<FavoritePodcast> = FavoritePodcast.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        
        if let result = try context.fetch(request).first {
            context.delete(result)
            try context.save()
        }
    }
    
    // MARK: - EPISODES (Likes)
    func toggleEpisodeLike(for episode: Episode) throws -> Bool {
        let id = episode.trackId
        
        if isEpisodeLiked(id: id) {
            try removeEpisode(id: Int64(id))
            return false
        } else {
            try saveEpisode(from: episode)
            return true
        }
    }
    
    func isEpisodeLiked(id: Int) -> Bool {
        let request: NSFetchRequest<FavoriteEpisode> = FavoriteEpisode.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", Int64(id))
        request.fetchLimit = 1
        return (try? context.count(for: request)) ?? 0 > 0
    }
    
    func fetchLikedEpisodes() -> [FavoriteEpisode] {
        let request: NSFetchRequest<FavoriteEpisode> = FavoriteEpisode.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Error fetching liked episodes: \(error)")
            return []
        }
    }
    
    private func saveEpisode(from episode: Episode) throws {
        let favorite = FavoriteEpisode(context: context)
        favorite.id = Int64(episode.trackId)
        favorite.title = episode.trackName
        favorite.audioUrl = episode.previewUrl
        favorite.coverUrl = episode.artworkUrl160
        favorite.author = episode.collectionName ?? "Unknown"
        favorite.createdAt = Date()
        favorite.duration = episode.durationInSeconds
        try context.save()
    }
    
    private func removeEpisode(id: Int64) throws {
        let request: NSFetchRequest<FavoriteEpisode> = FavoriteEpisode.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        
        if let result = try context.fetch(request).first {
            context.delete(result)
            try context.save()
        }
    }
}
