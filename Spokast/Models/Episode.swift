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
    
    enum CodingKeys: String, CodingKey {
        case trackId
        case trackName
        case description
        case releaseDate
        case trackTimeMillis
        case previewUrl
        case artworkUrl160
    }
}
