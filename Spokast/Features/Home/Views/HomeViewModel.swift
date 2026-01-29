//
//  HomeViewModel.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/09/25.
//

import Foundation
import Combine

// MARK: - Section Model
struct HomeSection {
    let title: String
    let podcasts: [Podcast]
}

// MARK: - View State
enum HomeViewState {
    case loading
    case success
    case error(String)
}

@MainActor
final class HomeViewModel {

    // MARK: - Dependencies
    private let apiService: PodcastServiceProtocol

    // MARK: - Outputs
    @Published private(set) var sections: [HomeSection] = []
    @Published private(set) var state: HomeViewState = .loading
    
    // MARK: - Initialization
    init(apiService: PodcastServiceProtocol) {
        self.apiService = apiService
    }

    // MARK: - Public Methods
    func fetchHomeData() {
        self.state = .loading
        
        Task {
            do {
                async let trendingFetch = apiService.fetchPodcasts(searchTerm: "podcast", limit: 8)
                async let techFetch = apiService.fetchPodcasts(searchTerm: "technology", limit: 10)
                async let comedyFetch = apiService.fetchPodcasts(searchTerm: "comedy", limit: 10)
                
                let (trending, tech, comedy) = try await (trendingFetch, techFetch, comedyFetch)
                
                self.sections = [
                    HomeSection(title: "Trending Now 🔥", podcasts: trending),
                    HomeSection(title: "Tech & Coding 💻", podcasts: tech),
                    HomeSection(title: "Relax & Laugh 😂", podcasts: comedy)
                ]
                
                self.state = .success
                
            } catch {
                let errorMessage = (error as? APIError)?.localizedDescription ?? "Failed to load home feed."
                self.state = .error(errorMessage)
            }
        }
    }
}
