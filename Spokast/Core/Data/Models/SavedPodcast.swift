//
//  SavedPodcast.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 24/01/26.
//

import Foundation
import SwiftData

@Model
final class SavedPodcast {
    
    @Attribute(.unique) var collectionId: Int
    var artistName: String
    var collectionName: String
    var feedUrl: String?
    var artworkUrl600: String?
    var primaryGenreName: String?
    var isSubscribed: Bool = true
    var addedAt: Date
    var category: Category?
    
    init(
        collectionId: Int,
        artistName: String,
        collectionName: String,
        feedUrl: String? = nil,
        artworkUrl600: String? = nil,
        primaryGenreName: String? = nil,
        category: Category? = nil
    ) {
        self.collectionId = collectionId
        self.artistName = artistName
        self.collectionName = collectionName
        self.feedUrl = feedUrl
        self.artworkUrl600 = artworkUrl600
        self.primaryGenreName = primaryGenreName
        self.addedAt = Date()
        self.category = category
    }
}

// MARK: - Helper para converter da API para o Banco
extension SavedPodcast {
    convenience init(from apiPodcast: Podcast, category: Category? = nil) {
        self.init(
            collectionId: apiPodcast.trackId ?? 0, 
            artistName: apiPodcast.artistName,
            collectionName: apiPodcast.collectionName,
            feedUrl: apiPodcast.feedUrl,
            artworkUrl600: apiPodcast.artworkUrl600,
            primaryGenreName: apiPodcast.primaryGenreName,
            category: category
        )
    }
}
