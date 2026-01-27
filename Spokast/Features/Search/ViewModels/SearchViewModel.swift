//
//  SearchViewModel.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 29/12/25.
//

import Foundation
import Combine

// MARK: - View State
enum SearchViewState {
    case idle
    case loading
    case success
    case empty
    case error(String)
}

@MainActor
final class SearchViewModel {
    
    // MARK: - Dependencies
    private let service: PodcastServiceProtocol
    
    // MARK: - Outputs
    @Published private(set) var podcasts: [Podcast] = []
    @Published private(set) var state: SearchViewState = .idle
    
    // MARK: - Init
    init(service: PodcastServiceProtocol) {
        self.service = service
    }
    
    // MARK: - Public Methods
    func executeSearch(for term: String) {
        let query = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            resetSearch()
            return
        }
        
        state = .loading
        
        Task {
            do {
                let results = try await service.fetchPodcasts(searchTerm: query, limit: 50)
                
                if results.isEmpty {
                    self.podcasts = []
                    self.state = .empty
                } else {
                    self.podcasts = results
                    self.state = .success
                }
                
            } catch {
                let errorMessage = (error as? APIError)?.localizedDescription ?? "Failed to search podcasts."
                self.state = .error(errorMessage)
            }
        }
    }
    
    func resetSearch() {
        podcasts = []
        state = .idle
    }
}
