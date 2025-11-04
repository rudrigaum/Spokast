//
//  APIServiceProtocol.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 28/10/25.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case decodingError(Error)
}

protocol APIServiceProtocol {
    func fetchPodcasts(searchTerm: String) async throws -> [Podcast]
}
