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
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Outputs
    @Published private(set) var title: String
    @Published private(set) var artist: String
    @Published private(set) var coverURL: URL?
    @Published private(set) var isPlaying: Bool = false
    
    // MARK: - Initialization
    init(episode: Episode,
         podcastImageURL: URL?,
         audioService: AudioPlayerProtocol = AudioService.shared) {
        
        self.episode = episode
        self.podcastImageURL = podcastImageURL
        self.audioService = audioService
        
        self.title = episode.trackName
        self.artist = "Podcast"
        self.coverURL = podcastImageURL
        
        setupBindings()
    }
    
    // MARK: - User Actions
    func didTapPlayPause() {
        if let urlString = episode.previewUrl, let url = URL(string: urlString) {
            audioService.toggle(url: url)
        }
    }
    
    func didTapForward() {
        print(">> Forward 30s tapped (Not implemented yet)")
    }
    
    func didTapRewind() {
        print("<< Rewind 15s tapped (Not implemented yet)")
    }
    
    // MARK: - Private Setup
    private func setupBindings() {
        audioService.playerState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                
                switch state {
                case .playing(let url):
                    self.isPlaying = (url.absoluteString == self.episode.previewUrl)
                    
                case .paused(let url):
                    if url.absoluteString == self.episode.previewUrl {
                        self.isPlaying = false
                    }
                    
                case .stopped:
                    self.isPlaying = false
                }
            }
            .store(in: &cancellables)
    }
}
