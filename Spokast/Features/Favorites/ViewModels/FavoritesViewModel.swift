//
//  FavoritesViewModel.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/12/25.
//

import Foundation
import Combine

enum FavoritesViewState: Equatable {
    case loading
    case empty
    case loaded([SavedPodcast])
    case error(String)
}

@MainActor
protocol FavoritesViewModelProtocol: AnyObject {
    var statePublisher: Published<FavoritesViewState>.Publisher { get }
    func loadFavorites()
}

@MainActor
final class FavoritesViewModel: FavoritesViewModelProtocol {
    
    // MARK: - Dependencies
    private let libraryService: LibraryServiceProtocol
    private let syncService: LibrarySyncServiceProtocol
    
    // MARK: - Output
    @Published private(set) var state: FavoritesViewState = .loading
    
    var statePublisher: Published<FavoritesViewState>.Publisher { $state }
    
    // MARK: - Init
    init(
        libraryService: LibraryServiceProtocol? = nil,
        syncService: LibrarySyncServiceProtocol? = nil
    ) {
        self.libraryService = libraryService ?? LibraryService()
        self.syncService = syncService ?? LibrarySyncService()
    }
    
    // MARK: - Methods
    func loadFavorites() {
        fetchLocalData()
    
        Task {
            await performSync()
        }
    }
    
    private func fetchLocalData() {
        if case .loading = state {
        }
        
        do {
            let items = try libraryService.fetchPodcasts()
            
            if items.isEmpty {
                state = .empty
            } else {
                state = .loaded(items)
            }
        } catch {
            print("❌ Error fetching library: \(error)")
            state = .error("Failed to load library.")
        }
    }
    
    private func performSync() async {
        do {
            let updatedCount = try await syncService.syncMissingMetadata()
            
            if updatedCount > 0 {
                fetchLocalData()
            }
        } catch {
            print("⚠️ Sync Warning: \(error.localizedDescription)")
        }
    }
}
