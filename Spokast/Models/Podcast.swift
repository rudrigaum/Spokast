//
//  Podcast.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 28/10/25.
//

import Foundation

struct Podcast: Codable {
    let trackId: Int?
    let collectionId: Int?
    let artistName: String?
    let collectionName: String?
    let artworkUrl100: String?
    let feedUrl: String?
    let artworkUrl600: String?
    let primaryGenreName: String?
    
    var id: Int {
        return collectionId ?? trackId ?? 0
    }
}

struct SearchResult: Decodable {
    let resultCount: Int
    let results: [Podcast]
}
