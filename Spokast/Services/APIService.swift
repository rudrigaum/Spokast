//
//  APIService.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 28/10/25.
//

import Foundation

enum APIServiceError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
}

final class APIService: APIServiceProtocol {

    func fetchPodcasts(searchTerm: String) async throws -> [Podcast] {
        guard let url = buildURL(for: searchTerm) else {
            throw APIError.invalidURL
        }

        let data: Data
        do {
            let (urlData, _) = try await URLSession.shared.data(from: url)
            data = urlData
        } catch {
            throw APIError.requestFailed(error)
        }

        do {
            let decoder = JSONDecoder()
            let searchResult = try decoder.decode(SearchResult.self, from: data)
            return searchResult.results
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func buildURL(for searchTerm: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "itunes.apple.com"
        components.path = "/search"

        components.queryItems = [
            URLQueryItem(name: "term", value: searchTerm),
            URLQueryItem(name: "media", value: "podcast"),
            URLQueryItem(name: "entity", value: "podcast"),
            URLQueryItem(name: "limit", value: "20")
        ]

        return components.url
    }
}

private struct EpisodeLookupResult: Decodable {
    let resultCount: Int
    let results: [Episode]
}

// MARK: - Extension for Episodes
extension APIService {
    
    func fetchEpisodes(for podcastId: Int) async throws -> [Episode] {
        
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        components?.queryItems = [
            URLQueryItem(name: "id", value: "\(podcastId)"),
            URLQueryItem(name: "entity", value: "podcastEpisode")
        ]
        
        guard let url = components?.url else {
            throw APIServiceError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIServiceError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let lookupResult = try decoder.decode(EpisodeLookupResult.self, from: data)
            let episodes = Array(lookupResult.results.dropFirst())
            return episodes
            
        } catch {
            print("Decoding error: \(error)")
            throw APIServiceError.decodingError
        }
    }
}
