//
//  Episode.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 19/12/25.
//

import Foundation

struct Episode: Decodable, Identifiable {
    var id: Int { trackId }
    let trackId: Int
    let trackName: String
    let description: String?
    let releaseDate: Date
    let trackTimeMillis: Int?
    let previewUrl: String?
    let artworkUrl160: String?
    let collectionName: String?
    let collectionId: Int
    let artworkUrl600: String?
    
    var durationInSeconds: Double {
        guard let millis = trackTimeMillis else { return 0.0 }
        return Double(millis) / 1000.0
    }
    
    enum CodingKeys: String, CodingKey {
        case trackId
        case trackName
        case description
        case releaseDate
        case trackTimeMillis
        case previewUrl
        case artworkUrl160
        case collectionName
        case collectionId
        case artworkUrl600
    }
}
