//
//  AudioPlayerService.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 29/12/25.
//

import Foundation
import AVFoundation
import Combine
import MediaPlayer

// MARK: - Enums & Protocols
enum AudioPlayerState: Equatable {
    case stopped
    case playing(url: URL)
    case paused(url: URL)
}

@MainActor
protocol AudioPlayerServiceProtocol {
    var playerStatePublisher: CurrentValueSubject<AudioPlayerState, Never> { get }
    var progressPublisher: PassthroughSubject<(currentTime: Double, duration: Double), Never> { get }
    var currentEpisodePublisher: CurrentValueSubject<Episode?, Never> { get }
    var playbackRatePublisher: CurrentValueSubject<Float, Never> { get }
    
    var currentEpisode: Episode? { get }
    var currentPodcastImageURL: URL? { get }
    
    func play(episode: Episode, from podcast: Podcast)
    func play(url: URL)
    func pause()
    func stop()
    func toggle(url: URL)
    func seek(to time: Double)
    func setPlaybackRate(_ rate: Float)
}

// MARK: - Service Implementation
@MainActor
final class AudioPlayerService: NSObject, AudioPlayerServiceProtocol {
    
    static let shared = AudioPlayerService()
    
    // MARK: - Properties
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var durationObservation: NSKeyValueObservation?
    var persistence: PlaybackPersistenceProtocol = SwiftDataPlaybackPersistence()
    
    let playerStatePublisher = CurrentValueSubject<AudioPlayerState, Never>(.stopped)
    let progressPublisher = PassthroughSubject<(currentTime: Double, duration: Double), Never>()
    let currentEpisodePublisher = CurrentValueSubject<Episode?, Never>(nil)
    let playbackRatePublisher = CurrentValueSubject<Float, Never>(1.0)
    
    var currentEpisode: Episode? {
        didSet { currentEpisodePublisher.send(currentEpisode) }
    }
    var currentPodcastImageURL: URL?
    
    // MARK: - Initialization
    private override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommands()
        
        Task {
            restoreLastState()
        }
    }
    
    // MARK: - Main Methods
    func play(episode: Episode, from podcast: Podcast) {
        self.currentEpisode = episode
        
        let artworkString = episode.artworkUrl600 ?? episode.artworkUrl160 ?? podcast.artworkUrl600 ?? podcast.artworkUrl100 ?? ""
        self.currentPodcastImageURL = URL(string: artworkString)
        
        if let previewUrl = episode.previewUrl, let url = URL(string: previewUrl) {
            self.play(url: url)
        }
    }
    
    func play(url: URL) {
        if case .paused(let currentUrl) = playerStatePublisher.value, currentUrl == url {
            player?.play()
            player?.rate = playbackRatePublisher.value
            playerStatePublisher.send(.playing(url: url))
            return
        }
        
        stop()
        
        let playerItem = AVPlayerItem(url: url)
        setupDurationObserver(for: playerItem)
        player = AVPlayer(playerItem: playerItem)
        player?.play()
        
        setupPeriodicTimeObserver()
        playerStatePublisher.send(.playing(url: url))
        player?.rate = playbackRatePublisher.value
        updateNowPlayingInfo()
    }
    
    func setPlaybackRate(_ rate: Float) {
        playbackRatePublisher.send(rate)
        if case .playing = playerStatePublisher.value {
            player?.rate = rate
            updateNowPlayingInfo()
        }
    }
    
    func pause() {
        player?.pause()
        if case .playing(let url) = playerStatePublisher.value {
            playerStatePublisher.send(.paused(url: url))
            saveCurrentState()
            updateNowPlayingInfo()
        }
    }
    
    func stop() {
        player?.pause()
        removePeriodicTimeObserver()
        durationObservation?.invalidate()
        durationObservation = nil
        player = nil
        playerStatePublisher.send(.stopped)
    }
    
    func toggle(url: URL) {
        switch playerStatePublisher.value {
        case .playing(let currentUrl):
            if currentUrl == url { pause() } else { play(url: url) }
        case .paused(let currentUrl):
            if currentUrl == url { play(url: url) } else { play(url: url) }
        case .stopped:
            play(url: url)
        }
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 1000)
        player?.seek(to: cmTime)
        updateNowPlayingInfo()
    }
    
    // MARK: - Private Setup (Audio & Remote Commands) 🛠️
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ AudioPlayerService Error: Failed to setup audio session: \(error)")
        }
    }
    
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            
            if case .paused(let url) = self.playerStatePublisher.value {
                self.play(url: url)
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            self?.seekRelative(by: -15)
            return .success
        }
        
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            self?.seekRelative(by: 30)
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: event.positionTime)
            return .success
        }
    }
    
    private func seekRelative(by seconds: Double) {
        guard let player = player else { return }
        let currentTime = player.currentTime().seconds
        let newTime = currentTime + seconds
        seek(to: newTime)
    }
    
    // MARK: - Now Playing Info (Lock Screen)
    private func updateNowPlayingInfo() {
        guard let episode = currentEpisode, let player = player else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var nowPlayingInfo = [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = episode.trackName
        nowPlayingInfo[MPMediaItemPropertyArtist] = episode.collectionName ?? episode.artistName ?? "Spokast"
        
        let duration = player.currentItem?.duration.seconds
        let safeDuration = (duration?.isFinite == true) ? duration! : 0.0
        let currentTime = player.currentTime().seconds
        let playbackRate = player.rate
        
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: safeDuration)
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: currentTime)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: playbackRate)
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        if let imageURL = currentPodcastImageURL {
            
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: imageURL), let image = UIImage(data: data) {
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in return image }
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self, let player = self.player else { return }
                        var currentInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
                        currentInfo[MPMediaItemPropertyArtwork] = artwork
                        currentInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: player.currentTime().seconds)
                        currentInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: player.rate)
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = currentInfo
                    }
                }
            }
        }
    }
    
    // MARK: - Time Observer
    private func setupPeriodicTimeObserver() {
        guard let player = player else { return }
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
    
            MainActor.assumeIsolated {
                guard let item = self.player?.currentItem else { return }
                
                let currentTime = time.seconds
                let duration = item.duration.seconds.isFinite ? item.duration.seconds : 0.0
                
                self.progressPublisher.send((currentTime: currentTime, duration: duration))
            }
        }
    }
    
    // MARK: - Duration Observer
    private func setupDurationObserver(for item: AVPlayerItem) {
        durationObservation?.invalidate()
        
        durationObservation = item.observe(\.duration, options: [.new]) { [weak self] item, _ in
            let duration = item.duration.seconds
            
            if duration > 0 && duration.isFinite {
                DispatchQueue.main.async {
                    self?.updateNowPlayingInfo()
                }
            }
        }
    }
    
    private func removePeriodicTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
    
    // MARK: - Persistence Logic
    @objc func saveCurrentState() {
        guard let episode = currentEpisode,
              let player = player else { return }
        
        let currentTime = player.currentTime().seconds
        let duration = player.currentItem?.duration.seconds ?? 0
        
        if currentTime < 5 || (duration > 0 && (duration - currentTime) < 3) {
            return
        }
        
        let podcastTitle = episode.collectionName ?? episode.artistName ?? "Podcast"
        
        let checkpoint = PlaybackCheckpoint(
            episode: episode,
            podcastTitle: podcastTitle,
            podcastArtWorkURL: currentPodcastImageURL,
            timestamp: currentTime,
            savedAt: Date()
        )
        
        do {
            try persistence.save(checkpoint: checkpoint)
        } catch {
            print("❌ Failed to save checkpoint: \(error)")
        }
    }
    
    // MARK: - Restoration Logic
    func restoreLastState() {
        guard let checkpoint = persistence.load() else {
            return
        }
        
        self.currentEpisode = checkpoint.episode
        self.currentPodcastImageURL = checkpoint.podcastArtWorkURL
        
        if let previewUrl = checkpoint.episode.previewUrl, let url = URL(string: previewUrl) {
            let playerItem = AVPlayerItem(url: url)
            player = AVPlayer(playerItem: playerItem)
            
            let cmTime = CMTime(seconds: checkpoint.timestamp, preferredTimescale: 1000)
            player?.seek(to: cmTime)
            playerStatePublisher.send(.paused(url: url))
            setupPeriodicTimeObserver()
        }
    }
}
