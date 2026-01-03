//
//  AudioPlayerService.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 29/12/25.
//

import Foundation
import AVFoundation
import Combine

// MARK: - Enums & Protocols
enum AudioPlayerState: Equatable {
    case stopped
    case playing(url: URL)
    case paused(url: URL)
}

protocol AudioPlayerServiceProtocol {
    var playerStatePublisher: CurrentValueSubject<AudioPlayerState, Never> { get }
    var progressPublisher: PassthroughSubject<(currentTime: Double, duration: Double), Never> { get }
    var currentEpisodePublisher: CurrentValueSubject<Episode?, Never> { get }
    
    var currentEpisode: Episode? { get }
    var currentPodcastImageURL: URL? { get }
    
    func play(episode: Episode, from podcast: Podcast)
    func play(url: URL)
    func pause()
    func stop()
    func toggle(url: URL)
    func seek(to time: Double)
}

// MARK: - Service Implementation
final class AudioPlayerService: AudioPlayerServiceProtocol {
    
    static let shared = AudioPlayerService()
    
    // MARK: - Properties
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    
    let playerStatePublisher = CurrentValueSubject<AudioPlayerState, Never>(.stopped)
    let progressPublisher = PassthroughSubject<(currentTime: Double, duration: Double), Never>()
    let currentEpisodePublisher = CurrentValueSubject<Episode?, Never>(nil)
    
    var currentEpisode: Episode? {
        didSet { currentEpisodePublisher.send(currentEpisode) }
    }
    var currentPodcastImageURL: URL?
    
    // MARK: - Initialization
    private init() {
        setupAudioSession()
    }
    
    // MARK: - Main Methods
    func play(episode: Episode, from podcast: Podcast) {
        self.currentEpisode = episode
        
        let artworkString = episode.artworkUrl600 ?? episode.artworkUrl160 ?? podcast.artworkUrl600 ?? podcast.artworkUrl100
        self.currentPodcastImageURL = URL(string: artworkString)
        
        if let previewUrl = episode.previewUrl, let url = URL(string: previewUrl) {
            self.play(url: url)
        }
    }
    
    func play(url: URL) {
        if case .paused(let currentUrl) = playerStatePublisher.value, currentUrl == url {
            player?.play()
            playerStatePublisher.send(.playing(url: url))
            return
        }
        
        stop()
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.play()
        
        setupPeriodicTimeObserver()
        playerStatePublisher.send(.playing(url: url))
    }
    
    func pause() {
        player?.pause()
        if case .playing(let url) = playerStatePublisher.value {
            playerStatePublisher.send(.paused(url: url))
        }
    }
    
    func stop() {
        player?.pause()
        removePeriodicTimeObserver()
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
    }
    
    // MARK: - Private Setup
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ AudioPlayerService Error: Failed to setup audio session: \(error)")
        }
    }
    
    private func setupPeriodicTimeObserver() {
        guard let player = player else { return }
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, let item = self.player?.currentItem else { return }
            
            let currentTime = time.seconds
            let duration = item.duration.seconds.isFinite ? item.duration.seconds : 0.0
            self.progressPublisher.send((currentTime: currentTime, duration: duration))
        }
    }
    
    private func removePeriodicTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
}
