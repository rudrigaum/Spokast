//
//  AudioService.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 22/12/25.
//

import Foundation
import AVFoundation
import Combine

enum AudioPlayerState: Equatable {
    case stopped
    case playing(url: URL)
    case paused(url: URL)
}

protocol AudioPlayerProtocol {
    var playerState: CurrentValueSubject<AudioPlayerState, Never> { get }
    var progressPublisher: PassthroughSubject<(currentTime: Double, duration: Double), Never> { get }
    var currentEpisode: Episode? { get }
    var currentPodcastImageURL: URL? { get }
    
    func play(url: URL)
    func play(episode: Episode, from podcast: Podcast)
    
    func pause()
    func stop()
    func toggle(url: URL)
    func seek(to time: Double)
}

final class AudioService: AudioPlayerProtocol {
    
    static let shared = AudioService()
    
    // MARK: - Properties
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    var currentEpisode: Episode?
    var currentPodcastImageURL: URL?
    
    let playerState = CurrentValueSubject<AudioPlayerState, Never>(.stopped)
    let progressPublisher = PassthroughSubject<(currentTime: Double, duration: Double), Never>()
    
    // MARK: - Initialization
    private init() {
        setupAudioSession()
    }
    
    // MARK: - Methods
    func play(episode: Episode, from podcast: Podcast) {
        self.currentEpisode = episode
        let artworkString = episode.artworkUrl600 ?? episode.artworkUrl160 ?? podcast.artworkUrl600 ?? podcast.artworkUrl100
    
        self.currentPodcastImageURL = URL(string: artworkString)
        
        if let previewUrl = episode.previewUrl, let url = URL(string: previewUrl) {
            self.play(url: url)
        }
    }
    
    func play(url: URL) {
        if case .paused(let currentUrl) = playerState.value, currentUrl == url {
            player?.play()
            playerState.send(.playing(url: url))
            return
        }
        
        stop()
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.play()
        
        setupPeriodicTimeObserver()
        
        playerState.send(.playing(url: url))
    }
    
    func pause() {
        player?.pause()
        if case .playing(let url) = playerState.value {
            playerState.send(.paused(url: url))
        }
    }
    
    func stop() {
        player?.pause()
        removePeriodicTimeObserver()
        player = nil
        playerState.send(.stopped)
    }
    
    func toggle(url: URL) {
        switch playerState.value {
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
            print("❌ AudioService Error: Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Time Observation (Core Logic)
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
