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

    // MARK: - Properties
    private var searchTask: Task<Void, Never>?

    // MARK: - Outputs
    @Published private(set) var podcasts: [Podcast] = []
    @Published private(set) var state: SearchViewState = .idle

    // MARK: - Initialization
    init(service: PodcastServiceProtocol) {
        self.service = service
    }

    // MARK: - Public Methods
    func executeSearch(for term: String) {
        let query = term.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !query.isEmpty else {
            resetSearch()
            return
        }

        searchTask?.cancel()

        podcasts = []
        state = .loading

        let service = service

        searchTask = Task { [weak self] in
            do {
                let results = try await service.fetchPodcasts(
                    searchTerm: query,
                    limit: 50
                )

                try Task.checkCancellation()

                guard let self else {
                    return
                }

                podcasts = results
                state = results.isEmpty ? .empty : .success
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled,
                      let self else {
                    return
                }

                podcasts = []

                let errorMessage =
                    (error as? APIError)?.localizedDescription
                    ?? "Failed to search podcasts."

                state = .error(errorMessage)
            }
        }
    }

    func resetSearch() {
        searchTask?.cancel()
        searchTask = nil

        podcasts = []
        state = .idle
    }
}
