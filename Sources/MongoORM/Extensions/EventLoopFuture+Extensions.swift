//
//  EventLoopFuture+Extensions.swift
//  BSON
//
//  Created by Jacob Sikorski on 2019-01-31.
//

import Foundation
import MongoKitten

extension EventLoopFuture where T == Document {
    
    /// Decode the object to the specified type
    ///
    /// - Parameter to: The type to decode the object to.
    /// - Returns: The decoded type furture.
    func decode<T: MongoDecodable>(to: T.Type) -> EventLoopFuture<T> {
        return self.thenThrowing({ document in
            return try T(document: document)
        })
    }
}

extension EventLoopFuture where T == Document? {
    
    /// Decode the object to the specified type
    ///
    /// - Parameter to: The type to decode the object to.
    /// - Returns: The decoded type furture.
    func decode<T: MongoDecodable>(to: T.Type) -> EventLoopFuture<T?> {
        return self.thenThrowing({ document in
            guard let document = document else { return nil }
            return try T(document: document)
        })
    }
}
