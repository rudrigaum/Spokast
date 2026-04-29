//
//  PodcastServiceMock.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 28/04/26.
//

import Foundation
@testable import Spokast

final class PodcastServiceMock: PodcastServiceProtocol, @unchecked Sendable {
    var podcastToReturnFromURL: Podcast?
    var podcastsToReturnFromSearch: [Podcast]?
    var shouldThrowError = false

    func fetchPodcast(byFeedUrl url: String) async throws -> Podcast {
        if shouldThrowError { throw URLError(.badServerResponse) }
        if let podcast = podcastToReturnFromURL { return podcast }
        throw URLError(.fileDoesNotExist)
    }

    func fetchPodcasts(searchTerm: String, limit: Int) async throws -> [Podcast] {
        if shouldThrowError { throw URLError(.badServerResponse) }
        return podcastsToReturnFromSearch ?? []
    }
}
