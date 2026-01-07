//
//  DownloadService.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 07/01/26.
//

import Foundation
import Combine

final class DownloadService: NSObject, DownloadServiceProtocol {
    
    // MARK: - Properties
    var activeDownloadsPublisher = CurrentValueSubject<[URL: DownloadStatus], Never>([:])
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    private var activeTasks: [URL: URLSessionDownloadTask] = [:]
    private let fileManager = FileManager.default
    
    // MARK: - DownloadServiceProtocol
    func startDownload(for episode: Episode) {
        guard let url = episode.streamUrl else { return }
        
        if hasLocalFile(for: episode) != nil {
            updateStatus(.downloaded(localURL: localFilePath(for: url)), for: url)
            return
        }
        
        if activeTasks[url] != nil { return }
        
        let task = session.downloadTask(with: url)
        activeTasks[url] = task
        task.resume()
        
        updateStatus(.downloading(progress: 0.0), for: url)
    }
    
    func cancelDownload(for episode: Episode) {
        guard let url = episode.streamUrl else { return }
        
        activeTasks[url]?.cancel()
        activeTasks[url] = nil
        
        updateStatus(.notDownloaded, for: url)
    }
    
    func hasLocalFile(for episode: Episode) -> URL? {
        guard let url = episode.streamUrl else { return nil }
        let localURL = localFilePath(for: url)
        return fileManager.fileExists(atPath: localURL.path) ? localURL : nil
    }
    
    func deleteLocalFile(for episode: Episode) {
        guard let url = episode.streamUrl else { return }
        
        let localURL = localFilePath(for: url)
        do {
            if fileManager.fileExists(atPath: localURL.path) {
                try fileManager.removeItem(at: localURL)
                print("🗑️ Deleted local file: \(localURL.lastPathComponent)")
            }
            updateStatus(.notDownloaded, for: url)
        } catch {
            print("❌ Error deleting file: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    private func updateStatus(_ status: DownloadStatus, for url: URL) {
        var current = activeDownloadsPublisher.value
        current[url] = status
        activeDownloadsPublisher.send(current)
    }
    
    private func localFilePath(for url: URL) -> URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(url.lastPathComponent)
    }
}

// MARK: - URLSessionDownloadDelegate

extension DownloadService: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let url = downloadTask.originalRequest?.url else { return }
        
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        updateStatus(.downloading(progress: progress), for: url)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let sourceURL = downloadTask.originalRequest?.url else { return }
        let destinationURL = localFilePath(for: sourceURL)
        
        do {
            try? fileManager.removeItem(at: destinationURL)
            
            try fileManager.moveItem(at: location, to: destinationURL)
            
            print("✅ Download finished: \(destinationURL.lastPathComponent)")
            activeTasks[sourceURL] = nil
            updateStatus(.downloaded(localURL: destinationURL), for: sourceURL)
            
        } catch {
            print("❌ File Move Error: \(error)")
            updateStatus(.failed(error: error), for: sourceURL)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let url = task.originalRequest?.url else { return }
        
        activeTasks[url] = nil
        
        if let error = error {
            if (error as NSError).code == NSURLErrorCancelled {
                updateStatus(.notDownloaded, for: url)
            } else {
                print("❌ Download Error: \(error.localizedDescription)")
                updateStatus(.failed(error: error), for: url)
            }
        }
    }
}
