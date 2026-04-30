//
//  PodcastServiceMock.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 28/04/26.
//

import Foundation
@testable import Spokast

final class PodcastServiceMock: PodcastServiceProtocol, @unchecked Sendable {

    // MARK: - Properties para controle do Mock
    var podcastToReturnFromURL: Podcast?
    var podcastsToReturnFromSearch: [Podcast]?
    var episodesToReturn: [Episode] = []
    var podcastDetailsToReturn: Podcast?
    var shouldThrowError = false

    // MARK: - Protocol Conformance
    func fetchPodcasts(searchTerm: String, limit: Int) async throws -> [Podcast] {
        if shouldThrowError { throw APIError.invalidResponse }
        return podcastsToReturnFromSearch ?? []
    }

    func fetchEpisodes(for podcastId: Int) async throws -> [Episode] {
        if shouldThrowError { throw APIError.invalidResponse }
        return episodesToReturn
    }

    func fetchPodcastDetails(id: Int) async throws -> Podcast {
        if shouldThrowError { throw APIError.invalidResponse }
        if let podcast = podcastDetailsToReturn { return podcast }
        throw APIError.invalidResponse
    }

    func fetchPodcast(byFeedUrl feedUrl: String) async throws -> Podcast? {
        if shouldThrowError { throw APIError.invalidResponse }
        return podcastToReturnFromURL
    }
}
