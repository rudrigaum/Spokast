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
            sortBy: [SortDescriptor(\SavedPodcast.collectionName)]
        )
        
        return try context.fetch(descriptor)
    }
}
