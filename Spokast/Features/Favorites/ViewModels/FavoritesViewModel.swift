//
//  FavoritesViewModel.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/12/25.
//

import Foundation
import Combine

enum FavoritesViewState {
    case loading
    case empty
    case content
}

final class FavoritesViewModel {
    
    // MARK: - Dependencies
    private let repository: FavoritesRepositoryProtocol
    
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Outputs
    @Published private(set) var podcasts: [FavoritePodcast] = []
    @Published private(set) var viewState: FavoritesViewState = .loading
    
    // MARK: - Initialization
    init(repository: FavoritesRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Methods
    func loadFavorites() {
        self.viewState = .loading
    
        let items = repository.fetchFollowedPodcasts()
        
        if items.isEmpty {
            self.podcasts = []
            self.viewState = .empty
        } else {
            self.podcasts = items
            self.viewState = .content
        }
    }
    
    func removePodcast(at index: Int) {
        guard podcasts.indices.contains(index) else { return }
        let podcastToRemove = podcasts[index]
        
        let dummyEpisode = Episode(
            trackId: 0,
            trackName: "",
            description: nil,
            releaseDate: Date(),
            trackTimeMillis: 0,
            previewUrl: nil,
            artworkUrl160: nil,
            collectionName: podcastToRemove.title,
            collectionId: Int(podcastToRemove.id),
            artworkUrl600: podcastToRemove.coverUrl
        )
        
        do {
            _ = try repository.togglePodcastSubscription(for: dummyEpisode)

            loadFavorites()
        } catch {
            print("❌ Error removing favorite: \(error)")
        }
    }
}
