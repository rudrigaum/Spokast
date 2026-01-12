//
//  DownloadServiceProtocol.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 07/01/26.
//

import Foundation
import Combine

enum DownloadStatus {
    case notDownloaded
    case downloading(progress: Float)
    case downloaded(localURL: URL)
    case failed(error: Error)
}

protocol DownloadServiceProtocol {
    var activeDownloadsPublisher: CurrentValueSubject<[URL: DownloadStatus], Never> { get }
    func startDownload(for episode: Episode)
    func cancelDownload(for episode: Episode)
    func hasLocalFile(for episode: Episode) -> URL?
    func deleteLocalFile(for episode: Episode)
}
