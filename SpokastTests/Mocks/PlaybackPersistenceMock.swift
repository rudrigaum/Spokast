//
//  PlaybackPersistenceMock.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 27/04/26.
//

import Foundation
@testable import Spokast

final class PlaybackPersistenceMock: PlaybackPersistenceProtocol, @unchecked Sendable {

    var savedCheckpoint: PlaybackCheckpoint?
    var mockCheckpoint: PlaybackCheckpoint?
    var didCallSave = false
    var didCallLoad = false

    func save(checkpoint: PlaybackCheckpoint) throws {
        didCallSave = true
        savedCheckpoint = checkpoint
    }

    func load() -> PlaybackCheckpoint? {
        didCallLoad = true
        return mockCheckpoint ?? savedCheckpoint
    }

    func clear() {
        savedCheckpoint = nil
        mockCheckpoint = nil
        didCallSave = false
        didCallLoad = false
    }
}
