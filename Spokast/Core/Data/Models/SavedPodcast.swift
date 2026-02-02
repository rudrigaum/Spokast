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
    var customCategory: String?
    
    init(
        collectionId: Int,
        artistName: String,
        collectionName: String,
        feedUrl: String? = nil,
        artworkUrl600: String? = nil,
        primaryGenreName: String? = nil,
        category: Category? = nil,
        customCategory: String? = nil
    ) {
        self.collectionId = collectionId
        self.artistName = artistName
        self.collectionName = collectionName
        self.feedUrl = feedUrl
        self.artworkUrl600 = artworkUrl600
        self.primaryGenreName = primaryGenreName
        self.isSubscribed = true
        self.addedAt = Date()
        self.category = category
        self.customCategory = customCategory
    }
}

// MARK: - Helper to convert from API to Database
extension SavedPodcast {
    convenience init(from apiPodcast: Podcast, category: Category? = nil) {
        self.init(
            collectionId: apiPodcast.collectionId ?? apiPodcast.trackId ?? 0,
            artistName: apiPodcast.artistName ?? "Unknown Artist",
            collectionName: apiPodcast.collectionName ?? "Unknown Podcast",
            feedUrl: apiPodcast.feedUrl,
            artworkUrl600: apiPodcast.artworkUrl600 ?? apiPodcast.artworkUrl100,
            primaryGenreName: apiPodcast.primaryGenreName,
            category: category,
            customCategory: nil 
        )
    }
}
