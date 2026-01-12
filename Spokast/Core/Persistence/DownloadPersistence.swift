//
//  DownloadPersistence.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 07/01/26.
//

import Foundation

protocol DownloadPersistenceProtocol {
    func saveDownloadedEpisode(_ episodeUrl: URL)
    func removeDownloadedEpisode(_ episodeUrl: URL)
    func getDownloadedEpisodes() -> Set<URL>
}

final class DownloadPersistence: DownloadPersistenceProtocol {
    
    private let key = "com.spokast.downloaded_episodes"
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func saveDownloadedEpisode(_ episodeUrl: URL) {
        var current = getDownloadedEpisodes()
        current.insert(episodeUrl)
        save(current)
    }
    
    func removeDownloadedEpisode(_ episodeUrl: URL) {
        var current = getDownloadedEpisodes()
        current.remove(episodeUrl)
        save(current)
    }
    
    func getDownloadedEpisodes() -> Set<URL> {
        guard let data = userDefaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([URL].self, from: data) else {
            return []
        }
        return Set(decoded)
    }
    
    private func save(_ episodes: Set<URL>) {
        let array = Array(episodes)
        if let encoded = try? JSONEncoder().encode(array) {
            userDefaults.set(encoded, forKey: key)
        }
    }
}
