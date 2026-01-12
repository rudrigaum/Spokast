//
//  APIServiceProtocol.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 28/10/25.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case requestFailed(Error)
    case decodingError(Error)
}

protocol APIServiceProtocol {
    func fetchPodcasts(searchTerm: String, limit: Int) async throws -> [Podcast]
    func fetchEpisodes(for podcastId: Int) async throws -> [Episode]
    func fetchPodcastDetails(id: Int) async throws -> Podcast
}
