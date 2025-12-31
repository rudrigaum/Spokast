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
    func togglePodcastSubscription(for podcast: Podcast) throws -> Bool
    func isPodcastFollowed(id: Int) -> Bool
    func fetchFollowedPodcasts() -> [FavoritePodcast]
    func toggleEpisodeLike(for episode: Episode) throws -> Bool
    func isEpisodeLiked(id: Int) -> Bool
    func fetchLikedEpisodes() -> [FavoriteEpisode]
    func removePodcast(id: Int64) throws
}

// MARK: - Implementation
final class FavoritesRepository: FavoritesRepositoryProtocol {
    
    private let context = CoreDataService.shared.viewContext
    
    // MARK: - PODCASTS
    func togglePodcastSubscription(for podcast: Podcast) throws -> Bool {
        let podcastId = podcast.trackId ?? 0
        
        if isPodcastFollowed(id: podcastId) {
            try removePodcast(id: Int64(podcastId))
            return false
        } else {
            try savePodcast(from: podcast)
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
    
    private func savePodcast(from podcastModel: Podcast) throws {
        let podcast = FavoritePodcast(context: context)
        podcast.id = Int64(podcastModel.trackId ?? 0)
        podcast.title = podcastModel.collectionName
        
        podcast.coverUrl = podcastModel.artworkUrl600 ?? podcastModel.artworkUrl100
        podcast.author = podcastModel.artistName
        podcast.createdAt = Date()
        
        try context.save()
    }
    
    func removePodcast(id: Int64) throws {
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
