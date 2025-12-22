//
//  AudioService.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 22/12/25.
//

import Foundation
import AVFoundation

protocol AudioPlayerProtocol {
    func play(url: URL)
    func pause()
    func stop()
}

final class AudioService: AudioPlayerProtocol {
    
    // MARK: - Properties
    static let shared = AudioService()
    private var player: AVPlayer?
    
    // MARK: - Initialization
    private init() {
        setupAudioSession()
    }
    
    // MARK: - Methods
    func play(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.play()
        print("▶️ AudioService: Playing \(url.lastPathComponent)")
    }
    
    func pause() {
        player?.pause()
        print("⏸️ AudioService: Paused")
    }
    
    func stop() {
        player?.pause()
        player = nil // Libera o recurso
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
