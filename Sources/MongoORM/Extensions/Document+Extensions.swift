//
//  Document+Extensions.swift
//  BSON
//
//  Created by Jacob Sikorski on 2019-01-28.
//

import Foundation
import MongoKitten

extension Document {
    
    /// Convert this document into an object.
    ///
    /// - Parameter type: The type of object we want to de-serialize to.
    /// - Returns: The object if successfully de-serialized.
    /// - Throws: Any error while de-serializing.
    func object<T: MongoDecodable>(_ type: T.Type) throws -> T {
        return try T(document: self)
    }
}
