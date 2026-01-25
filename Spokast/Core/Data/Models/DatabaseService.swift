//
//  DatabaseService.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 24/01/26.
//

import Foundation
import SwiftData

@MainActor
final class DatabaseService {
    
    static let shared = DatabaseService()
    
    let container: ModelContainer
    let context: ModelContext
    
    private init() {
        do {
            let schema = Schema([
                EpisodeProgress.self,
                Category.self,
                SavedPodcast.self
            ])
            
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            self.container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.context = container.mainContext
            
            print("✅ DatabaseService initialized successfully with path: \(modelConfiguration.url.path(percentEncoded: false))")
            
        } catch {
            fatalError("❌ Failed to initialize DatabaseService: \(error)")
        }
    }
}
