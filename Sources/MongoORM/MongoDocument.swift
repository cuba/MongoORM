//
//  MongoDocument.swift
//  App
//
//  Created by Jacob Sikorski on 2018-11-26.
//

import Foundation
import MongoKitten
import MapCodableKit

public protocol MongoDocument: MapCodable {
    var oid: ObjectId? { get set }
}

public extension Array where Element: MongoDocument {
    public func first(for oid: ObjectId) -> Iterator.Element? {
        return first(forId: oid.hexString)
    }
    
    func first(forId id: String) -> Element? {
        return first(where: { $0.oid?.hexString == id })
    }
    
    @discardableResult
    mutating func remove(with oid: ObjectId) -> Iterator.Element? {
        return remove(withId: oid.description)
    }
    
    @discardableResult
    mutating func remove(withId id: String) -> Element? {
        guard let index = firstIndex(where: { $0.oid?.hexString == id }) else { return nil }
        return self.remove(at: index)
    }
    
    mutating func add(_ element: Element) {
        if let id = element.oid?.hexString, let index = self.firstIndex(where: { $0.oid?.hexString == id }) {
            self[index] = element
        } else {
            self.append(element)
        }
    }
}
