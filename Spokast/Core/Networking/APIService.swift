//
//  APIService.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 28/10/25.
//

import Foundation

final class APIService: APIServiceProtocol {

    func fetchPodcasts(searchTerm: String, limit: Int = 20) async throws -> [Podcast] {
        guard let url = buildURL(for: searchTerm, limit: limit) else {
            throw APIError.invalidURL
        }

        let data: Data
        do {
            let (urlData, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
            
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

    private func buildURL(for searchTerm: String, limit: Int) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "itunes.apple.com"
        components.path = "/search"

        components.queryItems = [
            URLQueryItem(name: "term", value: searchTerm),
            URLQueryItem(name: "media", value: "podcast"),
            URLQueryItem(name: "entity", value: "podcast"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]

        return components.url
    }
}

// MARK: - Internal Models
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
            throw APIError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let lookupResult = try decoder.decode(EpisodeLookupResult.self, from: data)
            let episodes = Array(lookupResult.results.dropFirst())
            return episodes
            
        } catch let error as APIError {
            throw error
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError(error)
        }
    }
    
    func fetchPodcastDetails(id: Int) async throws -> Podcast {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        components?.queryItems = [
            URLQueryItem(name: "id", value: "\(id)")
        ]
        
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            let lookupResult = try decoder.decode(SearchResult.self, from: data)
            
            guard let podcast = lookupResult.results.first else {
                throw APIError.decodingError(NSError(domain: "PodcastNotFound", code: 404, userInfo: nil))
            }
            
            return podcast
            
        } catch {
            throw APIError.requestFailed(error)
        }
    }
}
