//
//  Document+Extensions.swift
//  BSON
//
//  Created by Jacob Sikorski on 2019-01-28.
//

import Foundation
import MongoKitten

typealias Key = String

extension Document {
    
    static func encode<T: Encodable>(_ codable: T) throws -> Document {
        let encoder = BSONEncoder()
        return try encoder.encode(codable)
    }
    
    /// Convert this document into a Codable object.
    ///
    /// - Parameter type: The type of object we want to de-serialize to.
    /// - Returns: The object if successfully de-serialized.
    /// - Throws: Any error while de-serializing.
    func decode<T: Decodable>(to type: T.Type) throws -> T {
        let decoder = BSONDecoder()
        return try decoder.decode(type, from: self)
    }
}
