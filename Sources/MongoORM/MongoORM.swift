//
//  MongoORM.swift
//  App
//
//  Created by Jacob Sikorski on 2018-11-26.
//

import Foundation
import MongoKitten
import MapCodableKit

typealias Query = MongoKitten.Query

public class MongoORM {
    public let database: MongoKitten.Database
    public let collection: MongoKitten.Collection
    
    public init(uri: URL, collectionName: String) throws {
        #if DEBUG
        print("MONGO: [CONNECTION] \(uri.absoluteString) -> \(collectionName)")
        #endif
        
        let database = try MongoKitten.Database(uri.absoluteString)
        self.database = database
        let collections = try database.listCollections()
        
        if let collection = collections.first(where: { $0.name == collectionName}) {
            self.collection = collection
        } else {
            self.collection = try database.createCollection(named: collectionName)
        }
    }
    
    public func update<T: MongoDocument>(_ document: T) throws -> T {
        guard let oid = document.oid else { throw DocumentUpdateError.missingObjectId }
        let query = MongoKitten.Query(aqt: .valEquals(key: "_id", val: oid))
        let map = try Map(document: document)
        let mongoDocument = try map.makeDocument()
        
        #if DEBUG
        print("MONGO: [UPDATE] \(mongoDocument)")
        #endif
        
        let response = try collection.update(query, to: mongoDocument, stoppingOnError: true)
        
        
        #if DEBUG
        print("MONGO: [RESULT] \(response)")
        #endif
        
        switch response {
        case 0:
            throw DocumentLoadError.documentNotFound
        default:
            return document
        }
    }
    
    public func insert<T: MongoDocument>(_ document: T) throws -> T {
        var document = document
        let map = try Map(document: document)
        let mongoDocument = try map.makeDocument()
        let response = try collection.insert(mongoDocument)
        document.oid = response as? ObjectId
        
        #if DEBUG
        print("MONGO: [INSERT] \(mongoDocument)")
        print("MONGO: [RESULT] \(response)")
        #endif
        
        return document
    }
    
    public func first<T: MongoDocument>(id: String) throws -> T {
        let oid = try MongoKitten.ObjectId(id)
        return try first(oid: oid)
    }
    
    public func first<T: MongoDocument>(oid: ObjectId) throws -> T {
        let query = MongoKitten.Query(aqt: .valEquals(key: "_id", val: oid))
        
        guard let first: T = try self.first(where: query) else {
            throw DocumentLoadError.documentNotFound
        }
        
        return first
    }
    
    public func first<T: MongoDocument>(where query: MongoKitten.Query = Query()) throws -> T? {
        guard let map = try self.find(where: query, skip: 0, limit: 1).first else { return nil }
        let object = try T(map: map)
        return object
    }
    
    public func all(skip: Int = 0, limit: Int = 0) throws -> [Map] {
        return try find(where: Query(), skip: skip, limit: limit)
    }
    
    public func find(where query: MongoKitten.Query, skip: Int = 0, limit: Int = 0) throws -> [Map] {
        let result = try collection.find(query, skipping: skip, limitedTo: limit)
        
        #if DEBUG
        print("MONGO: [FIND] \(query)")
        print("MONGO: [RESULT] \(result)")
        #endif
        
        var mapArray: [Map] = []
        
        for document in result {
            let jsonString = document.makeExtendedJSONString()
            let map = try Map(jsonString: jsonString)
            mapArray.append(map)
        }
        
        return mapArray
    }
    
    public func destroy<T: MongoDocument>(_ document: T) throws {
        guard let oid = document.oid else { throw DocumentDeleteError.missingObjectId }
        try destroy(oid: oid)
    }
    
    public func destroy(id: String) throws {
        let oid = try MongoKitten.ObjectId(id)
        try destroy(oid: oid)
    }
    
    public func destroy(oid: MongoKitten.ObjectId) throws {
        let query = MongoKitten.Query(aqt: .valEquals(key: "_id", val: oid))
        let result = try collection.remove(query, limitedTo: 1, stoppingOnError: true)
        
        switch result {
        case 0:
            throw DocumentLoadError.documentNotFound
        default:
            break
        }
    }
}

extension ObjectId: MapCodable {
    public init(map: Map) throws {
        let id: String = try map.value(from: "$oid")
        try self.init(id)
    }
    
    public func fill(map: Map) throws {
        try map.add(hexString, for: "$oid")
    }
}
