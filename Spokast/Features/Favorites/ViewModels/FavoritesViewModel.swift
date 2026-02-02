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
    var availableGenres: [String] { get }
    var currentFilter: String? { get }
    
    func loadFavorites()
    func filter(by genre: String?)
    func getPodcastDomainObject(at indexPath: IndexPath) -> Podcast?
    func updatePodcastCategory(podcastId: Int, newCategory: String?)
}

// MARK: - ViewModel
@MainActor
final class FavoritesViewModel: FavoritesViewModelProtocol {
    
    // MARK: - Dependencies
    private let libraryService: LibraryServiceProtocol
    private let syncService: LibrarySyncServiceProtocol
    
    // MARK: - Data Source
    private var allSections: [FavoritesSection] = []
    private var filteredSections: [FavoritesSection] = []
    
    // MARK: - Output
    @Published private(set) var state: FavoritesViewState = .loading
    @Published private(set) var currentFilter: String? = nil
    
    var statePublisher: Published<FavoritesViewState>.Publisher { $state }
    
    var availableGenres: [String] {
        return allSections.map { $0.title }
    }
    
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
    
    func filter(by genre: String?) {
        self.currentFilter = genre
        applyFilter()
    }
    
    func getPodcastDomainObject(at indexPath: IndexPath) -> Podcast? {
        guard indexPath.section < filteredSections.count else { return nil }
        let section = filteredSections[indexPath.section]
        
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
    
    func updatePodcastCategory(podcastId: Int, newCategory: String?) {
        Task {
            do {
                try await libraryService.updateCategory(for: podcastId, to: newCategory)
                fetchLocalData()
                
            } catch {
                print("❌ Error updating category: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    private func fetchLocalData() {
        do {
            let podcasts = try libraryService.fetchPodcasts()
            
            if podcasts.isEmpty {
                self.allSections = []
                self.filteredSections = []
                self.state = .empty
            } else {
                self.allSections = createSections(from: podcasts)
                applyFilter()
            }
        } catch {
            print("❌ Error fetching library: \(error)")
            self.state = .error("Failed to load library.")
        }
    }
    
    private func applyFilter() {
        if let genre = currentFilter {
            self.filteredSections = allSections.filter { $0.title == genre }
        } else {
            self.filteredSections = allSections
        }
        
        if filteredSections.isEmpty {
            if allSections.isEmpty {
                state = .empty
            } else {
                state = .loaded([])
            }
        } else {
            state = .loaded(filteredSections)
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
            
            let displayGenre = podcast.customCategory ?? podcast.primaryGenreName ?? "Uncategorized"
            
            return FavoriteItem(
                collectionId: podcast.collectionId,
                title: podcast.collectionName,
                artist: podcast.artistName,
                artworkUrl: podcast.artworkUrl600,
                feedUrl: podcast.feedUrl,
                genre: displayGenre
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
