//
//  PodcastDetailViewModel.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 09/12/25.
//

import Foundation
import Combine

final class PodcastDetailViewModel {
    
    // MARK: - Properties
    let podcast: Podcast
    private let service: APIService
    private let audioPlayerService: AudioPlayerServiceProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol
    private let downloadService: DownloadServiceProtocol

    private var downloadStatuses: [URL: DownloadStatus] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Outputs
    @Published private(set) var episodes: [Episode] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var currentPlayingEpisodeId: Int? = nil
    @Published private(set) var isPlayerPaused: Bool = false
    @Published private(set) var isFavorite: Bool = false
    @Published var isPlaying: Bool = false
    @Published var currentPlayingID: Int?
    @Published var onDownloadsUpdate: Void?
    
    // MARK: - Initialization
    init(podcast: Podcast,
         service: APIService,
         favoritesRepository: FavoritesRepositoryProtocol,
         audioPlayerService: AudioPlayerServiceProtocol = AudioPlayerService.shared,
         downloadService: DownloadServiceProtocol = DownloadService()) {
        
        self.podcast = podcast
        self.service = service
        self.favoritesRepository = favoritesRepository
        self.audioPlayerService = audioPlayerService
        self.downloadService = downloadService
        
        setupAudioObserver()
        checkFavoriteStatus()
        bindDownloads()
    }
    
    // MARK: - Computed Properties
    var title: String { return podcast.collectionName }
    var artist: String { return podcast.artistName }
    var genre: String { return podcast.primaryGenreName ?? "Podcast" }
    var coverImageURL: URL? {
        let urlString = podcast.artworkUrl600 ?? podcast.artworkUrl100
        return URL(string: urlString)
    }
    
    // MARK: - API Methods
    func fetchEpisodes() {
        guard let id = podcast.trackId else {
            self.errorMessage = "Invalid Podcast ID"
            return
        }
        
        Task {
            do {
                let fetchedEpisodes = try await service.fetchEpisodes(for: id)
                await MainActor.run {
                    self.episodes = fetchedEpisodes
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Could not load episodes."
                    print("Error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Subscription Logic
    func checkFavoriteStatus() {
        guard let id = podcast.trackId else { return }
        isFavorite = favoritesRepository.isPodcastFollowed(id: id)
    }
    
    func didTapSubscribe() {
        do {
            let newState = try favoritesRepository.togglePodcastSubscription(for: self.podcast)
            isFavorite = newState
        } catch {
            print("❌ Error toggling subscription: \(error)")
        }
    }
    
    // MARK: - Audio Methods
    func playEpisode(at index: Int) {
        guard episodes.indices.contains(index) else { return }
        let episode = episodes[index]
        audioPlayerService.play(episode: episode, from: podcast)
    }
    
    func didTapPlay(episode: Episode) {
        audioPlayerService.play(episode: episode, from: podcast)
    }
    
    // MARK: - Download Logic
    private func bindDownloads() {
        downloadService.activeDownloadsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] statuses in
                self?.downloadStatuses = statuses
                self?.onDownloadsUpdate = ()
            }
            .store(in: &cancellables)
    }
    
    func getDownloadStatus(for episode: Episode) -> DownloadButton.State {
        guard let url = episode.streamUrl else { return .notDownloaded }
        
        if let status = downloadStatuses[url] {
            switch status {
            case .downloading(let progress): return .downloading(progress: progress)
            case .downloaded: return .downloaded
            case .notDownloaded, .failed: return .notDownloaded
            }
        }
        
        if let localURL = downloadService.hasLocalFile(for: episode) {
            return .downloaded
        }
        
        return .notDownloaded
    }
    
    func toggleDownload(for episode: Episode) {
        let status = getDownloadStatus(for: episode)
        
        switch status {
        case .notDownloaded:
            downloadService.startDownload(for: episode)
        case .downloading:
            downloadService.cancelDownload(for: episode)
        case .downloaded:
            break
        }
    }
    
    func deleteEpisode(_ episode: Episode) {
        downloadService.deleteLocalFile(for: episode)
    }
    
    private func getPlayableURL(for episode: Episode) -> URL? {
        if let local = downloadService.hasLocalFile(for: episode) { return local }
        if let remote = episode.streamUrl { return remote }
        return nil
    }
    
    // MARK: - Private Setup & Helpers
    private func setupAudioObserver() {
        audioPlayerService.playerStatePublisher
            .receive(on: DispatchQueue.main)
            .map { state -> Bool in
                if case .playing = state { return true }
                return false
            }
            .assign(to: \.isPlaying, on: self)
            .store(in: &cancellables)
        
        audioPlayerService.currentEpisodePublisher
            .receive(on: DispatchQueue.main)
            .map { $0?.id }
            .assign(to: \.currentPlayingID, on: self)
            .store(in: &cancellables)
    }
}
