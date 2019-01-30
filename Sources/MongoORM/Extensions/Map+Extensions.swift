//
//  Map.swift
//  App
//
//  Created by Jacob Sikorski on 2018-11-26.
//

import Foundation
import MongoKitten
import MapCodableKit

public extension Map {
    
    /**
     Decodes a value stored for a key into a `MongoKitten.Document` and returns it
     
     - throws: Throws a `DocumentSaveError.unsupportedType` error if one of the values is not a `MongoKitten.Primitive`
     - returns: A `MongoKitten.Document` containing all the fields in the map
     */
    public func makeDocument() throws -> MongoKitten.Document {
        var document = MongoKitten.Document()
        
        for (key, primitive) in try primitivesDictionary() {
            // Remove nil values
            guard let primitive = primitive else { continue }
            document[key] = primitive
        }
        
        return document
    }
    
    public func primitivesDictionary() throws -> [String: Primitive?] {
        var dictionary: [String: Primitive?] = [:]
        
        for (key, value) in makeDictionary() {
            // Add empty values
            guard let value = value else {
                dictionary[key] = nil
                continue
            }
            
            // Ensure the value supports primitive
            guard let primitive = value as? Primitive else {
                throw DocumentSaveError.unsupportedType(key: key)
            }
            
            // Add the primitive
            dictionary[key] = primitive
        }
        
        return dictionary
    }
    
    /// Add an oid to this map.
    ///
    /// - Parameter oid: The oid to add.
    /// - Throws: Any errors when adding this object to the map.
    public func add(_ oid: ObjectId) throws {
        try self.add(oid as Any, for: "_id")
    }
    
    /// Return the oid of this object.
    ///
    /// - Returns: The oid of this object.
    /// - Throws: If the value is missing or is incorrectly formatted.
    public func oid() throws -> ObjectId {
        guard let value: Any = try value(from: "_id") else {
            throw DocumentLoadError.missingObjectId
        }
        
        guard let objectId = value as? ObjectId else {
            throw MapDecodingError.unexpectedType(key: "_id", expected: ObjectId.self, received: type(of: value).self)
        }
        
        return objectId
    }
}

public extension MapEncodable {
    public func makeDocument() throws -> Document {
        let map = try filledMap()
        return try map.makeDocument()
    }
    
    public func primitivesDictionary() throws -> [String: Primitive?] {
        let map = try filledMap()
        return try map.primitivesDictionary()
    }
}


