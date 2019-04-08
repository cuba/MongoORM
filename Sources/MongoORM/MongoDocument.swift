//
//  MongoObject.swift
//  App
//
//  Created by Jacob Sikorski on 2018-11-26.
//

import Foundation
import MongoKitten

public typealias ObjectId = MongoKitten.ObjectId

public protocol MongoEncodable {
    var _id: ObjectId { get }
    func makeDocument() throws -> MongoKitten.Document
    
    mutating func willSave() throws
    mutating func didSave()
}

public protocol MongoDecodable {
    init(document: Document) throws
}

public protocol MongoObject: MongoEncodable, MongoDecodable {
    
}

extension MongoObject {
    var oid: ObjectId {
        return _id
    }
    
    public func willSave() throws {}
    public func didSave() {}
    
    public static func willLoad(document: Document) throws -> Document {
        return document
    }
}

public extension Array where Element: MongoObject {
    func first(for oid: ObjectId) -> Iterator.Element? {
        return first(forId: oid.hexString)
    }
    
    func first(forId id: String) -> Element? {
        return first(where: { $0._id.hexString == id })
    }
    
    @discardableResult
    mutating func remove(with oid: ObjectId) -> Iterator.Element? {
        return remove(withId: oid.description)
    }
    
    @discardableResult
    mutating func remove(withId id: String) -> Element? {
        guard let index = firstIndex(where: { $0._id.hexString == id }) else { return nil }
        return self.remove(at: index)
    }
    
    mutating func add(_ element: Element) {
        if let index = self.firstIndex(where: { $0._id == element._id }) {
            self[index] = element
        } else {
            self.append(element)
        }
    }
}

public extension Decodable {
    init(document: Document) throws {
        self = try document.decode(to: Self.self)
    }
}

public extension Encodable {
    func makeDocument() throws -> Document {
        return try Document.encode(self)
    }
}
