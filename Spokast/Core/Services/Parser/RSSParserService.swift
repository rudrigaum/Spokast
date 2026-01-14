//
//  RSSParserService.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 12/01/26.
//

import Foundation

protocol RSSParserServiceProtocol {
    func parse(feedURL: URL) async throws -> [Episode]
}

final class RSSParserService: NSObject, RSSParserServiceProtocol {
    
    // MARK: - Properties
    private var parser: XMLParser?
    private var episodes: [Episode] = []
    private var currentParsingError: Error?
    
    private var currentElement = ""
    private var currentTitle: String = ""
    private var currentDescription: String = ""
    private var currentPubDate: String = ""
    private var currentStreamUrl: String = ""
    private var currentDuration: String = ""
    private var currentImage: String = ""
    private var isInsideItem = false
    private var continuation: CheckedContinuation<[Episode], Error>?
    private lazy var dateFormats: [DateFormatter] = {
        let locales = ["en_US_POSIX", "en_US"]
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss zzz",
            "dd MMM yyyy HH:mm:ss Z",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        var formatters: [DateFormatter] = []
        
        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatters.append(formatter)
        }
        return formatters
    }()
    
    // MARK: - Public API
    func parse(feedURL: URL) async throws -> [Episode] {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.startParsing(url: feedURL)
        }
    }
    
    // MARK: - Private Setup
    private func startParsing(url: URL) {
        episodes = []
        currentParsingError = nil
        
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.continuation?.resume(throwing: error)
                self.continuation = nil
                return
            }
            
            guard let data = data else {
                self.continuation?.resume(throwing: URLError(.badServerResponse))
                self.continuation = nil
                return
            }
            
            self.parser = XMLParser(data: data)
            self.parser?.delegate = self
            self.parser?.parse()
        }
        task.resume()
    }
}

// MARK: - XMLParserDelegate
extension RSSParserService: XMLParserDelegate {
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "item" {
            isInsideItem = true
            currentTitle = ""
            currentDescription = ""
            currentPubDate = ""
            currentStreamUrl = ""
            currentDuration = ""
            currentImage = ""
        }
        
        if isInsideItem && elementName == "enclosure" {
            if let url = attributeDict["url"] {
                currentStreamUrl = url
            }
        }
        
        if isInsideItem && elementName == "itunes:duration" {
            currentDuration = ""
        }
        
        if isInsideItem && elementName == "itunes:image" {
            if let href = attributeDict["href"] {
                currentImage = href
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isInsideItem else { return }
        
        let data = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch currentElement {
        case "title":
            currentTitle += string
        case "description", "itunes:summary", "content:encoded":
            currentDescription += string
        case "pubDate":
            currentPubDate += string
        case "itunes:duration":
            currentDuration += data
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            let episode = makeEpisode()
            episodes.append(episode)
            isInsideItem = false
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        continuation?.resume(returning: episodes)
        continuation = nil
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        continuation?.resume(throwing: parseError)
        continuation = nil
    }
    
    // MARK: - Helper Construction
    private func makeEpisode() -> Episode {
        let cleanTitle = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
        let cleanDesc = currentDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        let cleanDateString = currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines)
        let date = parseDate(from: cleanDateString)
        let uniqueID = currentStreamUrl.deterministicHash
        let durationMillis = parseDuration(currentDuration)
        
        return Episode(
            trackId: uniqueID,
            trackName: cleanTitle,
            description: cleanDesc,
            releaseDate: date,
            trackTimeMillis: durationMillis,
            previewUrl: currentStreamUrl,
            episodeUrl: currentStreamUrl,
            artworkUrl160: nil,
            collectionName: nil,
            collectionId: 0,
            artworkUrl600: currentImage.isEmpty ? nil : currentImage,
            artistName: nil
        )
    }
    
    private func parseDate(from string: String) -> Date {
        for formatter in dateFormats {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return Date()
    }
    
    private func parseDuration(_ durationString: String) -> Int? {
        let cleanString = durationString.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = cleanString.components(separatedBy: ":")
        var seconds = 0
        
        if components.count == 3 {
            let hours = Int(components[0]) ?? 0
            let minutes = Int(components[1]) ?? 0
            let secs = Int(components[2]) ?? 0
            seconds = (hours * 3600) + (minutes * 60) + secs
        } else if components.count == 2 {
            let minutes = Int(components[0]) ?? 0
            let secs = Int(components[1]) ?? 0
            seconds = (minutes * 60) + secs
        } else {
            seconds = Int(cleanString) ?? 0
        }
        
        return seconds * 1000
    }
}

extension String {
    var deterministicHash: Int {
        var hash = 5381
        for char in self.utf8 {
            hash = ((hash << 5) &+ hash) &+ Int(char)
        }
        return abs(hash)
    }
}
