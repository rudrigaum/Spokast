//
//  HomeViewModel.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/09/25.
//

import Foundation

protocol HomeViewModelDelegate: AnyObject {
    func didFetchPodcastsSuccessfully()
    func didFailToFetchPodcasts(with error: String)
}

@MainActor
final class HomeViewModel {

    // MARK: - Properties
    weak var delegate: HomeViewModelDelegate?
    private let apiService: APIServiceProtocol
    private(set) var podcasts: [Podcast] = []

    // MARK: - Initialization
    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }

    // MARK: - Public Methods
    func fetchPodcasts() {
        Task {
            do {
                let fetchedPodcasts = try await apiService.fetchPodcasts(searchTerm: "swift news")
                self.podcasts = fetchedPodcasts
                delegate?.didFetchPodcastsSuccessfully()
            } catch {
                let errorMessage = (error as? APIError)?.localizedDescription ?? "An unknown error occurred."
                delegate?.didFailToFetchPodcasts(with: errorMessage)
            }
        }
    }
}
