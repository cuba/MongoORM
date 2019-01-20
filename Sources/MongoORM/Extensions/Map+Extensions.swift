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
    
    public convenience init(document: MongoDocument) throws {
        self.init()
        try document.fill(map: self)
    }
    
    /**
     Decodes a value stored for a key into a `MongoKitten.Document` and returns it
     
     - throws: Throws a `DocumentSaveError.unsupportedType` error if one of the values is not a `MongoKitten.Primitive`
     - returns: A `MongoKitten.Document` containing all the fields in the map
     */
    public func makeDocument() throws -> MongoKitten.Document {
        let primitives = try self.makePrimitives()
        let document = MongoKitten.Document(dictionaryElements: primitives)
        
        return document
    }
    
    /**
     Converts this entire object into `MongoKitten.Primitive` dictionary elements containing all the fields stored in the map.
     
     - throws: Throws a `DocumentSaveError.unsupportedType` error if one of the values is not a `MongoKitten.Primitive`
     - returns: `MongoKitten.Primitive` dictionary elements containing all the fields in the map
     */
    private func makePrimitives() throws -> [(String, Primitive?)] {
        var primitives: [(String, Primitive?)] = []
        
        for (key, value) in makeDictionary() {
            // Remove nil values
            guard let value = value else { continue }
            
            guard let primitive = value as? Primitive else {
                throw DocumentSaveError.unsupportedType(key: key)
            }
            
            primitives.append((key, primitive))
        }
        
        return primitives
    }
}
