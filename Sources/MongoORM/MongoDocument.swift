//
//  MongoObject.swift
//  App
//
//  Created by Jacob Sikorski on 2018-11-26.
//

import Foundation
import MongoKitten
import MapCodableKit

public typealias ObjectId = MongoKitten.ObjectId

public protocol MongoObject {
    var oid: ObjectId { get }
    init(document: Document) throws
    func makeDocument() throws -> MongoKitten.Document
}

public extension Array where Element: MongoObject {
    public func first(for oid: ObjectId) -> Iterator.Element? {
        return first(forId: oid.hexString)
    }
    
    func first(forId id: String) -> Element? {
        return first(where: { $0.oid.hexString == id })
    }
    
    @discardableResult
    mutating func remove(with oid: ObjectId) -> Iterator.Element? {
        return remove(withId: oid.description)
    }
    
    @discardableResult
    mutating func remove(withId id: String) -> Element? {
        guard let index = firstIndex(where: { $0.oid.hexString == id }) else { return nil }
        return self.remove(at: index)
    }
    
    mutating func add(_ element: Element) {
        if let index = self.firstIndex(where: { $0.oid == element.oid }) {
            self[index] = element
        } else {
            self.append(element)
        }
    }
}

public protocol MongoMappable: MongoObject, MapCodable {
    
}

public extension MapCodable {
    public init(document: Document) throws {
        let keys = document.keys
        var json: [String: Any?] = [:]
        
        for key in keys {
            json[key] = document[key]
        }
        
        try self.init(json: json)
    }
}
