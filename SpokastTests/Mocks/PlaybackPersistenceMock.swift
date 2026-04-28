//
//  PlaybackPersistenceMock.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 27/04/26.
//

import Foundation
@testable import Spokast

final class PlaybackPersistenceMock: PlaybackPersistenceProtocol {
    var savedCheckpoint: PlaybackCheckpoint?
    var didCallSave = false
    var didCallLoad = false

    func save(checkpoint: PlaybackCheckpoint) throws {
        didCallSave = true
        savedCheckpoint = checkpoint
    }

    func load() -> PlaybackCheckpoint? {
        didCallLoad = true
        return savedCheckpoint
    }

    func clear() {
        savedCheckpoint = nil
        didCallSave = false
        didCallLoad = false
    }
}
