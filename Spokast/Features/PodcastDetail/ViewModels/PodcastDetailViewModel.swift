//
//  PodcastDetailViewModel.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 09/12/25.
//

import Foundation
import Combine

@MainActor
final class PodcastDetailViewModel {
    
    // MARK: - Properties
    let podcast: Podcast
    private let repository: PodcastRepositoryProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol
    private let audioPlayerService: AudioPlayerServiceProtocol
    private let downloadService: DownloadServiceProtocol
    private let libraryService: LibraryServiceProtocol

    private var downloadStatuses: [URL: DownloadStatus] = [:]
    private var cancellables = Set<AnyCancellable>()

    private var allEpisodes: [Episode] = []
    private var playedEpisodeIds: Set<Int> = []
    private var currentSearchQuery: String = ""
    
    // MARK: - Outputs
    @Published private(set) var episodes: [Episode] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var currentPlayingEpisodeId: Int? = nil
    @Published private(set) var isPlayerPaused: Bool = false
    @Published var isPlaying: Bool = false
    @Published var currentPlayingID: Int?
    
    @Published private(set) var isFavorite: Bool = false
    @Published private(set) var shouldHidePlayed: Bool = false
    @Published var onDownloadsUpdate: Void?
    
    // MARK: - Initialization
    init(
        podcast: Podcast,
        repository: PodcastRepositoryProtocol = PodcastRepository(),
        favoritesRepository: FavoritesRepositoryProtocol,
        libraryService: LibraryServiceProtocol? = nil,
        audioPlayerService: AudioPlayerServiceProtocol? = nil,
        downloadService: DownloadServiceProtocol = DownloadService()
    ) {
        
        self.podcast = podcast
        self.repository = repository
        self.favoritesRepository = favoritesRepository
        self.libraryService = libraryService ?? LibraryService()
        self.downloadService = downloadService
        self.audioPlayerService = audioPlayerService ?? AudioPlayerService.shared
        
        setupAudioObserver()
        checkFavoriteStatus()
        bindDownloads()
    }
    
    // MARK: - Computed Properties
    var title: String {
        return podcast.collectionName ?? "Unknown Title"
    }
    
    var artist: String {
        return podcast.artistName ?? "Unknown Artist"
    }
    
    var genre: String {
        return podcast.primaryGenreName ?? "Podcast"
    }
    
    var coverImageURL: URL? {
        guard let urlString = podcast.artworkUrl600 ?? podcast.artworkUrl100 else {
            return nil
        }
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
                async let fetchedEpisodes = try repository.fetchEpisodes(for: id)
                async let localPlayedIds = try libraryService.getPlayedEpisodeIds(for: id)
                
                let episodes = try await fetchedEpisodes
                let playedIds = try await localPlayedIds
                
                await MainActor.run {
                    self.allEpisodes = episodes
                    self.playedEpisodeIds = playedIds // Atualiza cache
                    self.applyFilters() // 👈 Aplica filtro inicial
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Could not load episodes."
                    print("❌ Error fetching data: \(error)")
                }
            }
        }
    }
    
    // MARK: - Filtering Logic (Unified)
    func filterEpisodes(with query: String) {
        self.currentSearchQuery = query
        applyFilters()
    }
    
    func toggleHidePlayed() {
        shouldHidePlayed.toggle()
        applyFilters()
    }
    
    private func applyFilters() {
        var result = allEpisodes
        
        if !currentSearchQuery.isEmpty {
            result = result.filter { episode in
                let matchesTitle = episode.trackName.localizedCaseInsensitiveContains(currentSearchQuery)
                let matchesDescription = episode.description?.localizedCaseInsensitiveContains(currentSearchQuery) ?? false
                return matchesTitle || matchesDescription
            }
        }
        
        if shouldHidePlayed {
            result = result.filter { !playedEpisodeIds.contains($0.trackId) }
        }
        
        self.episodes = result
    }
    
    // MARK: - Played Status Logic
    func isEpisodePlayed(_ episode: Episode) -> Bool {
        return playedEpisodeIds.contains(episode.trackId)
    }
    
    func togglePlayedStatus(for episode: Episode) {
        if playedEpisodeIds.contains(episode.trackId) {
            playedEpisodeIds.remove(episode.trackId)
        } else {
            playedEpisodeIds.insert(episode.trackId)
        }
        applyFilters() // Re-filtra a lista imediatamente
        
        Task {
            do {
                let confirmedStatus = try await libraryService.toggleEpisodePlayedStatus(episode)
                
                if confirmedStatus {
                    playedEpisodeIds.insert(episode.trackId)
                } else {
                    playedEpisodeIds.remove(episode.trackId)
                }
            } catch {
                print("❌ Error toggling played status: \(error)")
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
        
        if downloadService.hasLocalFile(for: episode) != nil {
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
        bindPlayerState()
        bindCurrentEpisode()
        bindPlaybackFinished()
    }
    
    // MARK: - Bindings Helpers
    private func bindPlayerState() {
        audioPlayerService.playerStatePublisher
            .receive(on: DispatchQueue.main)
            .map { state -> Bool in
                if case .playing = state { return true }
                return false
            }
            .assign(to: \.isPlaying, on: self)
            .store(in: &cancellables)
    }
    
    private func bindCurrentEpisode() {
        audioPlayerService.currentEpisodePublisher
            .receive(on: DispatchQueue.main)
            .map { $0?.id }
            .assign(to: \.currentPlayingID, on: self)
            .store(in: &cancellables)
    }
    
    private func bindPlaybackFinished() {
        audioPlayerService.playbackDidEndPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.handlePlaybackFinished()
            }
            .store(in: &cancellables)
    }
    
    private func handlePlaybackFinished() {
        guard let playingId = currentPlayingID else {
            return
        }
        
        guard let episode = episodes.first(where: { $0.id == playingId }) else {
            return
        }
        
        if isEpisodePlayed(episode) {
            return
        }
        
        togglePlayedStatus(for: episode)
    }
}
