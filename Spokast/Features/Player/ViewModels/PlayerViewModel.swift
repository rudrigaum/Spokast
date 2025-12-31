//
//  PlayerViewModel.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 23/12/25.
//

import Foundation
import Combine

final class PlayerViewModel {
    
    // MARK: - Dependencies
    private let episode: Episode
    private let podcastImageURL: URL?
    private let audioService: AudioPlayerProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private var currentDuration: Double = 0.0
    
    // MARK: - Outputs
    @Published private(set) var title: String
    @Published private(set) var artist: String
    @Published private(set) var coverURL: URL?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var isFavorite: Bool = false
    @Published private(set) var progressValue: Float = 0.0
    @Published private(set) var currentTimeText: String = "00:00"
    @Published private(set) var durationText: String = "--:--"
    
    // MARK: - Initialization
    init(episode: Episode,
         podcastImageURL: URL?,
         audioService: AudioPlayerProtocol = AudioService.shared,
         favoritesRepository: FavoritesRepositoryProtocol) {
        
        self.episode = episode
        self.podcastImageURL = podcastImageURL
        self.audioService = audioService
        self.favoritesRepository = favoritesRepository
        
        self.title = episode.trackName
        self.artist = episode.collectionName ?? "Podcast"
        self.coverURL = podcastImageURL
        
        setupBindings()
        checkFavoriteStatus()
    }
    
    // MARK: - User Actions
    func didTapPlayPause() {
        if let urlString = episode.previewUrl, let url = URL(string: urlString) {
            audioService.toggle(url: url)
        }
    }
    
    func didTapForward() {
        let newTime = (progressValue * Float(currentDuration)) + 30
        audioService.seek(to: Double(newTime))
    }
    
    func didTapRewind() {
        let newTime = (progressValue * Float(currentDuration)) - 15
        audioService.seek(to: Double(newTime))
    }
    
    func didScrub(to value: Float) {
        let targetTime = Double(value) * currentDuration
        audioService.seek(to: targetTime)
    }
    
    func didTapFavorite() {
        do {
            let newState = try favoritesRepository.togglePodcastSubscription(for: episode.asPodcast)
            isFavorite = newState
        } catch {
            print("❌ Error toggling subscription: \(error)")
        }
    }
    
    // MARK: - Private Setup
    private func checkFavoriteStatus() {
        isFavorite = favoritesRepository.isPodcastFollowed(id: episode.collectionId)
    }
    
    private func setupBindings() {
        bindPlayerState()
        bindProgress()
    }
    
    // MARK: - Helper Handlers
    private func bindPlayerState() {
        audioService.playerState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handlePlayerStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func bindProgress() {
        audioService.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (currentTime, duration) in
                self?.handleProgressUpdate(currentTime: currentTime, duration: duration)
            }
            .store(in: &cancellables)
    }
    
    private func handlePlayerStateChange(_ state: AudioPlayerState) {
        switch state {
        case .playing(let url):
            self.isPlaying = (url.absoluteString == self.episode.previewUrl)
        case .paused(let url):
            if url.absoluteString == self.episode.previewUrl { self.isPlaying = false }
        case .stopped:
            self.isPlaying = false
        }
    }
    
    private func handleProgressUpdate(currentTime: Double, duration: Double) {
        self.currentDuration = duration
        
        self.currentTimeText = self.formatTime(currentTime)
        self.durationText = self.formatTime(duration)
        
        if duration > 0 {
            self.progressValue = Float(currentTime / duration)
        } else {
            self.progressValue = 0.0
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let seconds = Int(time) % 60
        let minutes = (Int(time) / 60) % 60
        let hours = Int(time) / 3600
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
