//
//  PlayerViewModel.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 23/12/25.
//

import Foundation
import Combine

@MainActor
final class PlayerViewModel {
    
    // MARK: - Dependencies
    private let episode: Episode
    private let podcastImageURL: URL?
    private let audioPlayerService: AudioPlayerServiceProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol
    private let downloadService: DownloadServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private var currentDuration: Double = 0.0
    private var rawDuration: Double = 0.0
    private var rawCurrentTime: Double = 0.0
    private var currentRate: Float = 1.0
    
    // MARK: - Outputs
    @Published private(set) var title: String
    @Published private(set) var artist: String
    @Published private(set) var coverURL: URL?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var isFavorite: Bool = false
    @Published private(set) var progressValue: Float = 0.0
    @Published private(set) var currentTimeText: String = "00:00"
    @Published private(set) var durationText: String = "00:00"
    @Published var playbackSpeedLabel: String = "1.0x"
    @Published var downloadState: DownloadButton.State = .notDownloaded
    
    var currentEpisode: Episode? {
        return audioPlayerService.currentEpisode
    }

    
    // MARK: - Initialization
    init(
        episode: Episode,
        podcastImageURL: URL?,
        audioService: AudioPlayerServiceProtocol? = nil,
        favoritesRepository: FavoritesRepositoryProtocol,
        downloadService: DownloadServiceProtocol? = nil
    ) {
        self.episode = episode
        self.podcastImageURL = podcastImageURL
        self.favoritesRepository = favoritesRepository
        
        self.audioPlayerService = audioService ?? AudioPlayerService.shared
        self.downloadService = downloadService ?? DownloadService()
        
        self.title = episode.trackName
        self.artist = episode.collectionName ?? "Podcast"
        self.coverURL = podcastImageURL
        
        setupBindings()
        checkFavoriteStatus()
        bindDownloadState()
    }
    
    // MARK: - User Actions
    func didTapPlayPause() {
        if let url = getPlayableURL() {
            audioPlayerService.toggle(url: url)
        }
    }
    
    func didTapForward() {
        let newTime = (progressValue * Float(currentDuration)) + 30
        audioPlayerService.seek(to: Double(newTime))
    }
    
    func didTapRewind() {
        let newTime = (progressValue * Float(currentDuration)) - 15
        audioPlayerService.seek(to: Double(newTime))
    }
    
    func didScrub(to value: Float) {
        let targetTime = Double(value) * currentDuration
        audioPlayerService.seek(to: targetTime)
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
        bindPlaybackRate()
        bindPlayerProgress()
    }
    
    // MARK: - Helper Handlers
    private func bindPlayerState() {
        audioPlayerService.playerStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handlePlayerStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func bindProgress() {
        audioPlayerService.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (currentTime, duration) in
                self?.handleProgressUpdate(currentTime: currentTime, duration: duration)
            }
            .store(in: &cancellables)
    }
    
    private func bindPlaybackRate() {
        audioPlayerService.playbackRatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rate in
                guard let self = self else { return }
                
                self.currentRate = rate
                self.playbackSpeedLabel = String(format: "%.1fx", rate)
                self.updateTimeDisplay()
            }
            .store(in: &cancellables)
    }
    
    private func bindPlayerProgress() {
        audioPlayerService.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (currentTime, duration) in
                guard let self = self else { return }
                
                self.rawCurrentTime = currentTime
                self.rawDuration = duration
                
                if duration > 0 {
                    self.progressValue = Float(currentTime / duration)
                } else {
                    self.progressValue = 0.0
                }
                
                self.updateTimeDisplay()
            }
            .store(in: &cancellables)
    }
    
    private func bindDownloadState() {
        downloadService.activeDownloadsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] downloads in
                guard let self = self, let url = self.episode.streamUrl else { return }
                
                if let status = downloads[url] {
                    self.mapDownloadStatusToUI(status)
                } else {
                    if self.downloadService.hasLocalFile(for: self.episode) != nil {
                        self.downloadState = .downloaded
                    } else {
                        self.downloadState = .notDownloaded
                    }
                }
            }
            .store(in: &cancellables)
    }
        
        private func mapDownloadStatusToUI(_ status: DownloadStatus) {
            switch status {
            case .notDownloaded:
                self.downloadState = .notDownloaded
            case .downloading(let progress):
                self.downloadState = .downloading(progress: progress)
            case .downloaded:
                self.downloadState = .downloaded
            case .failed:
                self.downloadState = .notDownloaded // Ou tratar erro
            }
        }
    
    private func getPlayableURL() -> URL? {
        if let localURL = downloadService.hasLocalFile(for: episode) {
            return localURL
        }
        
        if let remoteURL = episode.streamUrl {
            return remoteURL
        }
        
        return nil
    }

    private func setupAudio() {
        guard let url = getPlayableURL() else { return }
        audioPlayerService.play(url: url)
    }
    
    private func updateTimeDisplay() {
        let safeRate = (currentRate > 0) ? Double(currentRate) : 1.0
        let scaledCurrentTime = rawCurrentTime / safeRate
        let scaledDuration = rawDuration / safeRate
        
        self.currentTimeText = formatTime(scaledCurrentTime)
        self.durationText = formatTime(scaledDuration)
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
    
    func togglePlaybackSpeed() {
        let currentRate = audioPlayerService.playbackRatePublisher.value
        let nextRate: Float
        
        if currentRate < 1.5 {
            nextRate = 1.5
        } else if currentRate < 2.0 {
            nextRate = 2.0
        } else {
            nextRate = 1.0
        }
        
        audioPlayerService.setPlaybackRate(nextRate)
    }
    
    func didTapDownload() {
        switch downloadState {
        case .notDownloaded:
            downloadService.startDownload(for: episode)
            
        case .downloading:
            downloadService.cancelDownload(for: episode)
            
        case .downloaded:
            break
        }
    }
    
    func deleteDownloadedEpisode() {
        downloadService.deleteLocalFile(for: episode)
    }
}
