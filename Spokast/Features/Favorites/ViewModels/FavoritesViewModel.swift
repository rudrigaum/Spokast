//
//  FavoritesViewModel.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/12/25.
//

import Foundation
import Combine

// MARK: - View State
enum FavoritesViewState: Equatable {
    case loading
    case empty
    case loaded([FavoritesSection])
    case error(String)
}

// MARK: - Protocol
@MainActor
protocol FavoritesViewModelProtocol: AnyObject {
    var statePublisher: Published<FavoritesViewState>.Publisher { get }
    func loadFavorites()
    func getPodcastDomainObject(at indexPath: IndexPath) -> Podcast?
}

// MARK: - ViewModel
@MainActor
final class FavoritesViewModel: FavoritesViewModelProtocol {
    
    // MARK: - Dependencies
    private let libraryService: LibraryServiceProtocol
    private let syncService: LibrarySyncServiceProtocol
    
    // MARK: - Data Source
    private var currentSections: [FavoritesSection] = []
    
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
    
    func getPodcastDomainObject(at indexPath: IndexPath) -> Podcast? {
        guard indexPath.section < currentSections.count else { return nil }
        let section = currentSections[indexPath.section]
        
        guard indexPath.row < section.items.count else { return nil }
        let item = section.items[indexPath.row]
        
        return Podcast(
            trackId: item.collectionId,
            collectionId: item.collectionId,
            artistName: item.artist,
            collectionName: item.title,
            artworkUrl100: item.artworkUrl ?? "",
            feedUrl: item.feedUrl,
            artworkUrl600: item.artworkUrl,
            primaryGenreName: item.genre
        )
    }
    
    // MARK: - Private Methods
    private func fetchLocalData() {
        do {
            let podcasts = try libraryService.fetchPodcasts()
            
            if podcasts.isEmpty {
                self.currentSections = []
                self.state = .empty
            } else {
                let sections = createSections(from: podcasts)
                self.currentSections = sections
                self.state = .loaded(sections)
            }
        } catch {
            print("❌ Error fetching library: \(error)")
            self.state = .error("Failed to load library.")
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
    
    // MARK: - Grouping & Mapping Logic
    private func createSections(from podcasts: [SavedPodcast]) -> [FavoritesSection] {
        let items: [FavoriteItem] = podcasts.map { podcast in
            FavoriteItem(
                collectionId: podcast.collectionId,
                title: podcast.collectionName,
                artist: podcast.artistName,
                artworkUrl: podcast.artworkUrl600,
                feedUrl: podcast.feedUrl,
                genre: podcast.primaryGenreName ?? "Uncategorized"
            )
        }
        
        let groupedDictionary = Dictionary(grouping: items) { item in
            return item.genre.isEmpty ? "Uncategorized" : item.genre
        }
        
        let sections = groupedDictionary.map { (key, value) -> FavoritesSection in
            let sortedItems = value.sorted { $0.title < $1.title }
            return FavoritesSection(title: key, items: sortedItems)
        }
        
        return sections.sorted { $0.title < $1.title }
    }
}
