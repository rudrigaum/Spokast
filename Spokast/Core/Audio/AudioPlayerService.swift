//
//  AudioPlayerService.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 29/12/25.
//

import Foundation
import AVFoundation
import Combine

protocol AudioPlayerServiceProtocol {
    var isPlaying: Bool { get }
    var currentEpisode: Episode? { get }
    var currentPodcast: Podcast? { get }
    
    var playerStatePublisher: Published<Bool>.Publisher { get }
    var currentEpisodePublisher: Published<Episode?>.Publisher { get }
    var currentPodcastPublisher: Published<Podcast?>.Publisher { get }
    
    func play(episode: Episode, from podcast: Podcast)
    func togglePlayPause()
}

final class AudioPlayerService: AudioPlayerServiceProtocol {
    
    // MARK: - Singleton
    static let shared = AudioPlayerService()
    
    // MARK: - Properties
    private var player: AVPlayer?
    
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentEpisode: Episode?
    @Published private(set) var currentPodcast: Podcast?
    
    var playerStatePublisher: Published<Bool>.Publisher { $isPlaying }
    var currentEpisodePublisher: Published<Episode?>.Publisher { $currentEpisode }
    var currentPodcastPublisher: Published<Podcast?>.Publisher { $currentPodcast }
    
    // MARK: - Init
    private init() {
        setupAudioSession()
    }
    
    // MARK: - Public Methods
    func play(episode: Episode, from podcast: Podcast) {
        if currentEpisode?.id == episode.id {
            togglePlayPause()
            return
        }
        
        guard let url = episode.streamUrl else {
            print("AudioPlayer: No valid stream URL for episode \(episode.trackName)")
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.play()
        
        self.currentEpisode = episode
        self.currentPodcast = podcast
        self.isPlaying = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
    
    @objc private func playerDidFinishPlaying() {
        isPlaying = false
    }
    
    // MARK: - Private Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session: \(error)")
        }
    }
}
