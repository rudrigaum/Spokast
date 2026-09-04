//
//  PodcastServiceMock.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 28/04/26.
//

import Foundation
@testable import Spokast

final class PodcastServiceMock: PodcastServiceProtocol, @unchecked Sendable {

    // MARK: - Search Handler
    var fetchPodcastsHandler: (
        (String, Int) async throws -> [Podcast]
    )?

    // MARK: - Stubbed Values
    var podcastToReturnFromURL: Podcast?
    var podcastsToReturnFromSearch: [Podcast]?
    var episodesToReturn: [Episode] = []
    var podcastDetailsToReturn: Podcast?

    var shouldThrowError = false

    // MARK: - Protocol Conformance
    func fetchPodcasts(
        searchTerm: String,
        limit: Int
    ) async throws -> [Podcast] {
        if let fetchPodcastsHandler {
            return try await fetchPodcastsHandler(
                searchTerm,
                limit
            )
        }

        if shouldThrowError {
            throw APIError.invalidResponse
        }

        return podcastsToReturnFromSearch ?? []
    }

    func fetchEpisodes(
        for podcastId: Int
    ) async throws -> [Episode] {
        if shouldThrowError {
            throw APIError.invalidResponse
        }

        return episodesToReturn
    }

    func fetchPodcastDetails(
        id: Int
    ) async throws -> Podcast {
        if shouldThrowError {
            throw APIError.invalidResponse
        }

        guard let podcast = podcastDetailsToReturn else {
            throw APIError.invalidResponse
        }

        return podcast
    }

    func fetchPodcast(
        byFeedUrl feedUrl: String
    ) async throws -> Podcast? {
        if shouldThrowError {
            throw APIError.invalidResponse
        }

        return podcastToReturnFromURL
    }
}
