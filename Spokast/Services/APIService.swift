//
//  APIService.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 28/10/25.
//

import Foundation

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
