//
//  Podcast.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 28/10/25.
//

import Foundation

struct Podcast: Decodable {
    let trackId: Int?
    let artistName: String
    let collectionName: String
    let artworkUrl100: String
    let feedUrl: String?
    let artworkUrl600: String?
    let primaryGenreName: String?
}

struct SearchResult: Decodable {
    let resultCount: Int
    let results: [Podcast]
}
