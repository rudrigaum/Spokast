//
//  OPMLImportService.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 24/01/26.
//

import Foundation
import SwiftData

@MainActor
final class OPMLImportService {
    
    // MARK: - Dependencies
    private let context: ModelContext
    private var categoryCache: [String: Category] = [:]
    
    // MARK: - Init
    init(context: ModelContext? = nil) {
        self.context = context ?? DatabaseService.shared.context
    }
    
    // MARK: - Public API
    func importOPML(from url: URL) async throws -> Int {
        let items = try await Task.detached(priority: .userInitiated) {
            let data = try Data(contentsOf: url)
            let parser = OPMLParser()
            return try parser.parse(data: data)
        }.value
        
        guard !items.isEmpty else { return 0 }
        var importedCount = 0
        
        for item in items {
            guard item.rssURL != nil else { continue }
            
            var category: Category? = nil
            if let categoryName = item.categoryName {
                category = try fetchOrCreateCategory(named: categoryName)
            }
            
            try upsertPodcast(from: item, category: category)
            importedCount += 1
        }
        
        try context.save()
        categoryCache.removeAll()
        
        return importedCount
    }
    
    // MARK: - Helper Logic
    private func fetchOrCreateCategory(named name: String) throws -> Category {
        if let cached = categoryCache[name] {
            return cached
        }
        
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.name == name }
        )
        
        if let existing = try context.fetch(descriptor).first {
            categoryCache[name] = existing
            return existing
        }
        
        let newCategory = Category(name: name)
        context.insert(newCategory)
        categoryCache[name] = newCategory
        return newCategory
    }
    
    private func upsertPodcast(from item: OPMLItem, category: Category?) throws {
        guard let feedUrl = item.rssURL else { return }
        let generatedId = generateStableID(from: feedUrl)
        
        let descriptor = FetchDescriptor<SavedPodcast>(
            predicate: #Predicate { $0.collectionId == generatedId }
        )
        
        if let existing = try context.fetch(descriptor).first {
            existing.category = category
        } else {
            let newPodcast = SavedPodcast(
                collectionId: generatedId,
                artistName: "Unknown Artist",
                collectionName: item.title,
                feedUrl: feedUrl,
                artworkUrl600: nil,
                primaryGenreName: nil,
                category: category
            )
            context.insert(newPodcast)
        }
    }
    
    private func generateStableID(from string: String) -> Int {
        var hash = 5381
        for char in string.utf8 {
            let shifted = hash &<< 5
            hash = (shifted &+ hash) &+ Int(char)
        }
        return abs(hash)
    }
}
