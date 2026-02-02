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
}

@MainActor
final class LibraryService: LibraryServiceProtocol {
    
    // MARK: - Dependencies
    private let context: ModelContext
    
    // MARK: - Init
    init(context: ModelContext? = nil) {
        self.context = context ?? DatabaseService.shared.context
    }
    
    // MARK: - Methods
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
}
