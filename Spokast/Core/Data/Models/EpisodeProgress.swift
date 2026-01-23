//
//  EpisodeProgress.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 23/01/26.
//
import Foundation
import SwiftData

@Model
final class EpisodeProgress {
    
    @Attribute(.unique) var episodeId: String
    @Attribute(.externalStorage) var episodeData: Data?
    
    var podcastId: String?
    var currentTime: Double
    var duration: Double
    var lastPlayedAt: Date
    var isCompleted: Bool
    var episodeTitle: String
    var podcastTitle: String
    var podcastArtWorkURLString: String?
    
    init(
        episodeId: String,
        podcastId: String? = nil,
        currentTime: Double,
        duration: Double,
        lastPlayedAt: Date = Date(),
        isCompleted: Bool = false,
        episodeTitle: String,
        podcastTitle: String,
        podcastArtWorkURLString: String? = nil,
        episodeData: Data? = nil
    ) {
        self.episodeId = episodeId
        self.podcastId = podcastId
        self.currentTime = currentTime
        self.duration = duration
        self.lastPlayedAt = lastPlayedAt
        self.isCompleted = isCompleted
        self.episodeTitle = episodeTitle
        self.podcastTitle = podcastTitle
        self.podcastArtWorkURLString = podcastArtWorkURLString
        self.episodeData = episodeData
    }
}
