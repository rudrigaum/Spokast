//
//  LibraryService.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/01/26.
//

import Foundation
import SwiftData

@MainActor
protocol LibraryServiceProtocol {
    func fetchPodcasts() throws -> [SavedPodcast]
    func updateCategory(for podcastId: Int, to newCategory: String?) async throws
    func getPlayedEpisodeIds(for podcastId: Int) throws -> Set<Int>
    func toggleEpisodePlayedStatus(_ episode: Episode) async throws -> Bool
}

@MainActor
final class LibraryService: LibraryServiceProtocol {
    
    // MARK: - Dependencies
    private let context: ModelContext
    
    // MARK: - Init
    init(context: ModelContext? = nil) {
        self.context = context ?? DatabaseService.shared.context
    }
    
    // MARK: - Podcast Methods
    func fetchPodcasts() throws -> [SavedPodcast] {
        let descriptor = FetchDescriptor<SavedPodcast>(
            sortBy: [SortDescriptor(\.collectionName)]
        )
        return try context.fetch(descriptor)
    }
    
    func updateCategory(for podcastId: Int, to newCategory: String?) async throws {
        let idToCheck = podcastId
        
        var descriptor = FetchDescriptor<SavedPodcast>(
            predicate: #Predicate { $0.collectionId == idToCheck }
        )
        descriptor.fetchLimit = 1
        
        if let podcast = try context.fetch(descriptor).first {
            podcast.customCategory = newCategory
            try context.save()
        }
    }
    
    // MARK: - Episode Methods
    func getPlayedEpisodeIds(for podcastId: Int) throws -> Set<Int> {
        let idToCheck = podcastId

        let descriptor = FetchDescriptor<SavedEpisode>(
            predicate: #Predicate { $0.podcastId == idToCheck && $0.isPlayed == true }
        )
        
        let episodes = try context.fetch(descriptor)
        return Set(episodes.map { $0.id })
    }
    
    func toggleEpisodePlayedStatus(_ episode: Episode) async throws -> Bool {
        let idToCheck = episode.trackId
        
        var descriptor = FetchDescriptor<SavedEpisode>(
            predicate: #Predicate { $0.id == idToCheck }
        )
        descriptor.fetchLimit = 1
        
        if let savedEpisode = try context.fetch(descriptor).first {
            savedEpisode.isPlayed.toggle()
            savedEpisode.lastPlayedAt = savedEpisode.isPlayed ? Date() : nil
            
            try context.save()
            return savedEpisode.isPlayed
            
        } else {
            let newSaved = SavedEpisode(from: episode)
            newSaved.isPlayed = true
            newSaved.lastPlayedAt = Date()
            
            context.insert(newSaved)
            try context.save()
            return true
        }
    }
}
