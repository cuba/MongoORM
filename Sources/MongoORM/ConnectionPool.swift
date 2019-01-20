//
//  ConnectionPool.swift
//  BSON
//
//  Created by Jacob Sikorski on 2019-01-20.
//

import Foundation
import MongoKitten

public class ConnectionPool {
    private var _database: MongoKitten.Database?
    public let url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    public func database() throws -> MongoKitten.Database {
        if let database = self._database {
            return database
        } else {
            let database = try MongoKitten.Database(url.absoluteString)
            self._database = database
            return database
        }
    }
    
    public func collection(forName name: String) throws -> MongoKitten.Collection {
        let database = try self.database()
        let collections = try database.listCollections()
        
        if let collection = collections.first(where: { $0.name == name}) {
            return collection
        } else {
            let collection = try database.createCollection(named: name)
            return collection
        }
    }
    
    public func orm<T: MongoDocument>(for type: MongoDocument.Type, collectionName: String) throws -> MongoORM<T> {
        let collection = try self.collection(forName: collectionName)
        return MongoORM<T>(collection: collection)
    }
}
