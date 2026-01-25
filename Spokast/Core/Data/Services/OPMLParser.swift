//
//  OPMLParser.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 24/01/26.
//

import Foundation

enum OPMLParserError: Error {
    case invalidData
    case parsingFailed(reason: String)
}

final class OPMLParser: NSObject {
    
    // MARK: - Properties
    private var items: [OPMLItem] = []
    private var categoryStack: [(name: String, depth: Int)] = []
    private var currentDepth: Int = 0
    private var parseCompletion: ((Result<[OPMLItem], Error>) -> Void)?
    
    // MARK: - Public API
    func parse(data: Data) async throws -> [OPMLItem] {
        return try await withCheckedThrowingContinuation { continuation in
            self.startParsing(data: data) { result in
                switch result {
                case .success(let items):
                    continuation.resume(returning: items)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Internal Parsing Logic
    private func startParsing(data: Data, completion: @escaping (Result<[OPMLItem], Error>) -> Void) {
        self.items = []
        self.categoryStack = []
        self.currentDepth = 0
        self.parseCompletion = completion
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        if !parser.parse() {
            let error = parser.parserError ?? OPMLParserError.parsingFailed(reason: "Unknown error")
            completion(.failure(error))
        }
    }
}

// MARK: - XMLParserDelegate
extension OPMLParser: XMLParserDelegate {
    
    func parserDidStartDocument(_ parser: XMLParser) {
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        guard elementName == "outline" else {
            if elementName == "body" || elementName == "opml" { return }
            currentDepth += 1
            return
        }
        
        currentDepth += 1
        
        let title = attributeDict["text"] ?? attributeDict["title"]
        let xmlUrl = attributeDict["xmlUrl"]
        let htmlUrl = attributeDict["htmlUrl"]
        
        if let feedUrl = xmlUrl, let feedTitle = title {
            let currentCategory = categoryStack.last?.name
            
            let item = OPMLItem(
                title: feedTitle,
                rssURL: feedUrl,
                siteURL: htmlUrl,
                categoryName: currentCategory
            )
            items.append(item)
            
        } else if let folderTitle = title {
            categoryStack.append((name: folderTitle, depth: currentDepth))
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "outline" {
            if let lastCategory = categoryStack.last, lastCategory.depth == currentDepth {
                categoryStack.removeLast()
            }
        }
        
        if elementName != "body" && elementName != "opml" {
             currentDepth -= 1
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        parseCompletion?(.success(items))
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        parseCompletion?(.failure(parseError))
    }
}
