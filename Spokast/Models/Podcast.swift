//
//  Podcast.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 28/10/25.
//

import Foundation

struct Podcast: Decodable {
    let artistName: String
    let collectionName: String
    let artworkUrl100: String
    let feedUrl: String?
}

struct SearchResult: Decodable {
    let resultCount: Int
    let results: [Podcast]
}
