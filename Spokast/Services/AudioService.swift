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
    func play(url: URL)
    func pause()
    func stop()
    func toggle(url: URL)
}

final class AudioService: AudioPlayerProtocol {
    
    static let shared = AudioService()
    
    // MARK: - Properties
    private var player: AVPlayer?
    let playerState = CurrentValueSubject<AudioPlayerState, Never>(.stopped)
    
    // MARK: - Initialization
    private init() {
        setupAudioSession()
    }
    
    // MARK: - Methods
    func play(url: URL) {
        if case .paused(let currentUrl) = playerState.value, currentUrl == url {
            player?.play()
            playerState.send(.playing(url: url))
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.play()
        
        playerState.send(.playing(url: url))
        print("▶️ AudioService: Playing \(url.lastPathComponent)")
    }
    
    func pause() {
        player?.pause()
        if case .playing(let url) = playerState.value {
            playerState.send(.paused(url: url))
            print("⏸️ AudioService: Paused")
        }
    }
    
    func stop() {
        player?.pause()
        player = nil
        playerState.send(.stopped)
    }
    
    func toggle(url: URL) {
        switch playerState.value {
        case .playing(let currentUrl):
            if currentUrl == url {
                pause()
            } else {
                play(url: url)
            }
        case .paused(let currentUrl):
            if currentUrl == url {
                play(url: url)
            } else {
                play(url: url)
            }
        case .stopped:
            play(url: url)
        }
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
}
