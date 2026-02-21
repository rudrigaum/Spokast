//
//  PodcastDetailMocks.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 19/02/26.
//

import Foundation
import Combine
@testable import Spokast

// MARK: - Mock Podcast Repository
final class MockPodcastRepository: PodcastRepositoryProtocol {
    var episodesToReturn: [Episode]
    var errorToThrow: Error?
    
    init(episodes: [Episode] = []) {
        self.episodesToReturn = episodes
    }
    
    func fetchEpisodes(for id: Int) async throws -> [Episode] {
        if let error = errorToThrow { throw error }
        return episodesToReturn
    }
}

// MARK: - Mock Favorites Repository
final class MockFavoritesRepository: FavoritesRepositoryProtocol {
    var isFollowed = false
    var followedPodcastsToReturn: [SavedPodcast] = []
    var isEpisodeLikedValue = false
    
    // MARK: - Protocol Conformance
    func isPodcastFollowed(id: Int) -> Bool {
        return isFollowed
    }
    
    func togglePodcastSubscription(for podcast: Podcast) throws -> Bool {
        isFollowed.toggle()
        return isFollowed
    }
    
    func fetchFollowedPodcasts() -> [SavedPodcast] {
        return followedPodcastsToReturn
    }
    
    func toggleEpisodeLike(for episode: Episode) throws -> Bool {
        isEpisodeLikedValue.toggle()
        return isEpisodeLikedValue
    }
    
    func isEpisodeLiked(id: Int) -> Bool {
        return isEpisodeLikedValue
    }
}

// MARK: - Mock Library Service
final class MockLibraryService: LibraryServiceProtocol {
    var podcastsToReturn: [SavedPodcast] = []
    var playedIdsToReturn: Set<Int> = []
    var lastUpdatedCategory: String?
    var lastUpdatedPodcastId: Int?
    
    func fetchPodcasts() throws -> [SavedPodcast] {
        return podcastsToReturn
    }
    
    func updateCategory(for podcastId: Int, to newCategory: String?) async throws {
        self.lastUpdatedPodcastId = podcastId
        self.lastUpdatedCategory = newCategory
    }
    
    func getPlayedEpisodeIds(for podcastId: Int) throws -> Set<Int> {
        return playedIdsToReturn
    }
    
    func toggleEpisodePlayedStatus(_ episode: Episode) async throws -> Bool {
        if playedIdsToReturn.contains(episode.trackId) {
            playedIdsToReturn.remove(episode.trackId)
            return false
        } else {
            playedIdsToReturn.insert(episode.trackId)
            return true
        }
    }
}

// MARK: - Mock Download Service
final class MockDownloadService: DownloadServiceProtocol {
    var activeDownloadsPublisher = CurrentValueSubject<[URL: DownloadStatus], Never>([:])
    
    var localFiles: [Int: URL] = [:]
    
    // MARK: - Protocol Methods
    func hasLocalFile(for episode: Episode) -> URL? {
        return localFiles[episode.trackId]
    }
    
    func startDownload(for episode: Episode) {
    }
    
    func cancelDownload(for episode: Episode) {
    }
    
    func deleteLocalFile(for episode: Episode) {
        localFiles.removeValue(forKey: episode.trackId)
    }
}

// MARK: - Mock Audio Player Service
final class MockAudioPlayerService: AudioPlayerServiceProtocol {
    
    // MARK: - Protocol Publishers (Assinaturas Exatas)
    var playerStatePublisher = CurrentValueSubject<AudioPlayerState, Never>(.stopped)
    var progressPublisher = PassthroughSubject<(currentTime: Double, duration: Double), Never>()
    var currentEpisodePublisher = CurrentValueSubject<Episode?, Never>(nil)
    var playbackRatePublisher = CurrentValueSubject<Float, Never>(1.0)
    var playbackDidEndPublisher = PassthroughSubject<Void, Never>()
    
    // MARK: - Protocol Properties
    var currentEpisode: Episode?
    var currentPodcastImageURL: URL?
    
    // MARK: - Protocol Methods
    func play(episode: Episode, from podcast: Podcast) {
        self.currentEpisode = episode
        self.currentEpisodePublisher.send(episode)
        
        if let url = URL(string: "https://spokast.mock/audio.mp3") {
            self.playerStatePublisher.send(.playing(url: url))
        }
    }
    
    func play(url: URL) {
        playerStatePublisher.send(.playing(url: url))
    }
    
    func pause() {
        if case .playing(let url) = playerStatePublisher.value {
            playerStatePublisher.send(.paused(url: url))
        }
    }
    
    func stop() {
        playerStatePublisher.send(.stopped)
    }
    
    func toggle(url: URL) {
        switch playerStatePublisher.value {
        case .playing(let currentUrl) where currentUrl == url:
            pause()
        default:
            play(url: url)
        }
    }
    
    func seek(to time: Double) {
    }
    
    func setPlaybackRate(_ rate: Float) {
        playbackRatePublisher.send(rate)
    }
}
