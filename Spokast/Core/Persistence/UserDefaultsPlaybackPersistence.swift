//
//  UserDefaultsPlaybackPersistence.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 05/01/26.
//

import Foundation

final class UserDefaultsPlaybackPersistence: PlaybackPersistenceProtocol {
    
    // MARK: - Properties
    private let userDefaults: UserDefaults
    private let storageKey = "com.spokast.playback_checkpoint"
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Initialization
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Protocol Implementation
    func save(checkpoint: PlaybackCheckpoint) throws {
        do {
            let data = try encoder.encode(checkpoint)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            print("💾 Persistence Error: Failed to encode checkpoint: \(error)")
            throw error
        }
    }
    
    func load() -> PlaybackCheckpoint? {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return nil
        }
        
        do {
            let checkpoint = try decoder.decode(PlaybackCheckpoint.self, from: data)
            return checkpoint
        } catch {
            print("💾 Persistence Error: Failed to decode checkpoint: \(error)")
            return nil
        }
    }
    
    func clear() {
        userDefaults.removeObject(forKey: storageKey)
    }
}
