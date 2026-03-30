//
//  OPMLImportServiceMock.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 26/03/26.
//

import Foundation
@testable import Spokast

final class OPMLImportServiceMock: OPMLImportServiceProtocol {
    private(set) var invokedImportOPML = false
    private(set) var importOPMLURL: URL?
    var stubbedImportOPMLResult: Result<Int, Error>!

    func importOPML(from url: URL) async throws -> Int {
        invokedImportOPML = true
        importOPMLURL = url
        return try stubbedImportOPMLResult.get()
    }
}
