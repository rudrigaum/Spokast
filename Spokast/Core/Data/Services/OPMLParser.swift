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
    
    // MARK: - State
    private var items: [OPMLItem] = []
    private var categoryStack: [(name: String, depth: Int)] = []
    private var currentDepth: Int = 0
    private var parseError: Error?
    
    // MARK: - Public API
    func parse(data: Data) throws -> [OPMLItem] {
        self.items = []
        self.categoryStack = []
        self.currentDepth = 0
        self.parseError = nil
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        let success = parser.parse()
        
        if let error = parseError {
            throw error
        }
        
        if !success {
            throw parser.parserError ?? OPMLParserError.parsingFailed(reason: "Unknown XML error")
        }
        
        return items
    }
}

// MARK: - XMLParserDelegate

extension OPMLParser: XMLParserDelegate {
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if parseError != nil { return }
        
        guard elementName == "outline" else {
            if elementName != "body" && elementName != "opml" && elementName != "head" {
                currentDepth += 1
            }
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
        if parseError != nil { return }
        
        if elementName == "outline" {
            if let lastCategory = categoryStack.last, lastCategory.depth == currentDepth {
                categoryStack.removeLast()
            }
        }
        
        if elementName != "body" && elementName != "opml" && elementName != "head" {
            currentDepth -= 1
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }
}
