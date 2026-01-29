//
//  APIService.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 28/10/25.
//

import Foundation

// MARK: - Service Implementation
final class PodcastService: PodcastServiceProtocol {
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Public Methods
    func fetchPodcasts(searchTerm: String, limit: Int = 20) async throws -> [Podcast] {
        guard let url = makeURL(endpoint: "search", queryItems: [
            URLQueryItem(name: "term", value: searchTerm),
            URLQueryItem(name: "media", value: "podcast"),
            URLQueryItem(name: "entity", value: "podcast"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]) else {
            throw APIError.invalidURL
        }

        let result: SearchResult = try await performRequest(url: url)
        return result.results
    }
    
    func fetchEpisodes(for podcastId: Int) async throws -> [Episode] {
        guard let url = makeURL(endpoint: "lookup", queryItems: [
            URLQueryItem(name: "id", value: "\(podcastId)"),
            URLQueryItem(name: "entity", value: "podcastEpisode"),
            URLQueryItem(name: "limit", value: "200")
        ]) else {
            throw APIError.invalidURL
        }
        
        let result: EpisodeLookupResult = try await performRequest(url: url)
        let episodes = Array(result.results.dropFirst())
        return episodes
    }
    
    func fetchPodcastDetails(id: Int) async throws -> Podcast {
        guard let url = makeURL(endpoint: "lookup", queryItems: [
            URLQueryItem(name: "id", value: "\(id)")
        ]) else {
            throw APIError.invalidURL
        }
        
        let result: SearchResult = try await performRequest(url: url)
        
        guard let podcast = result.results.first else {
            throw APIError.decodingError(NSError(domain: "PodcastNotFound", code: 404, userInfo: nil))
        }
        
        return podcast
    }
    
    func fetchPodcast(byFeedUrl feedUrl: String) async throws -> Podcast? {
        guard let url = makeURL(endpoint: "search", queryItems: [
            URLQueryItem(name: "term", value: feedUrl),
            URLQueryItem(name: "media", value: "podcast"),
            URLQueryItem(name: "entity", value: "podcast"),
            URLQueryItem(name: "limit", value: "1")
        ]) else {
            throw APIError.invalidURL
        }
        
        let result: SearchResult = try await performRequest(url: url)
        return result.results.first
    }
    
    // MARK: - Private Helpers
    private func performRequest<T: Decodable>(url: URL) async throws -> T {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        let session = URLSession(configuration: config)
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            if let httpResponse = response as? HTTPURLResponse {
                print("❌ HTTP Error: \(httpResponse.statusCode) para URL: \(url.absoluteString)")
            }
            throw APIError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            print("❌ Decoding Error for \(T.self): \(error)")
            throw APIError.decodingError(error)
        }
    }
    
    private func makeURL(endpoint: String, queryItems: [URLQueryItem]) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "itunes.apple.com"
        components.path = "/\(endpoint)"
        components.queryItems = queryItems
        return components.url
    }
}

// MARK: - Internal Models
private struct EpisodeLookupResult: Decodable {
    let resultCount: Int
    let results: [Episode]
}
