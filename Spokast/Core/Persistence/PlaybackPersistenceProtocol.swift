//
//  PlaybackPersistenceProtocol.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 05/01/26.
//

import Foundation

struct PlaybackCheckpoint: Codable {
    let episode: Episode
    let podcastTitle: String
    let podcastArtWorkURL: URL?
    let timestamp: Double
    let savedAt: Date
}

@MainActor
protocol PlaybackPersistenceProtocol {
    func save(checkpoint: PlaybackCheckpoint) throws
    func load() -> PlaybackCheckpoint?
    func clear()
}
