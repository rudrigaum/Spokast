//
//  FavoritesRepository.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 25/12/25.
//

import Foundation
import CoreData
import Combine

protocol FavoritesRepositoryProtocol {
    func save(_ episode: Episode) throws
    func remove(episodeId: Int64) throws
    func isFavorite(episodeId: Int64) -> Bool
    func fetchFavorites() -> [FavoriteEpisode]
}

final class FavoritesRepository: FavoritesRepositoryProtocol {
    
    private let context = CoreDataService.shared.viewContext
    
    // MARK: - Save
    func save(_ episode: Episode) throws {
        if isFavorite(episodeId: Int64(episode.trackId)) { return }
        
        let favorite = FavoriteEpisode(context: context)
        favorite.id = Int64(episode.trackId)
        favorite.title = episode.trackName
        favorite.audioUrl = episode.previewUrl
        favorite.createdAt = Date()
        favorite.coverUrl = episode.artworkUrl160
        favorite.author = episode.collectionName ?? "Unknown Podcast"
        favorite.duration = episode.durationInSeconds
        
        try context.save()
    }
    
    // MARK: - Delete
    func remove(episodeId: Int64) throws {
        let fetchRequest: NSFetchRequest<FavoriteEpisode> = FavoriteEpisode.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", episodeId)
        
        if let result = try context.fetch(fetchRequest).first {
            context.delete(result)
            try context.save()
        }
    }
    
    // MARK: - Check
    func isFavorite(episodeId: Int64) -> Bool {
        let fetchRequest: NSFetchRequest<FavoriteEpisode> = FavoriteEpisode.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", episodeId)
        fetchRequest.fetchLimit = 1
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            return false
        }
    }
    
    // MARK: - Fetch All
    func fetchFavorites() -> [FavoriteEpisode] {
        let fetchRequest: NSFetchRequest<FavoriteEpisode> = FavoriteEpisode.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("❌ Error fetching favorites: \(error)")
            return []
        }
    }
}
