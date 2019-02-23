//
//  Collection+Extensions.swift
//  BSON
//
//  Created by Jacob Sikorski on 2019-01-26.
//

import Foundation
import MongoKitten

public extension MongoKitten.Collection {
    
    // MARK: - Save
    
    /// Insert an object into the collection.
    /// Note: If the oid of the object is not added to the map, it will generate a new ObjectId.
    ///
    /// - Parameter object: The object to save.
    /// - Returns: An EventLoopFuture that returns the inserted object.
    /// - Throws: Either an error with mapping the object or a `MongoKitten` error.
    public func insert<T: MongoEncodable>(_ object: T) throws -> EventLoopFuture<T> {
        var object = object
        
        // Inform callback
        try object.willSave()
        
        let document = try object.makeDocument()
        return self.insert(document).thenThrowing({ reply in
            guard reply.isSuccessful else {
                if let message = reply.errorMessage {
                    throw DocumentSaveError.recievedMessage(message)
                } else {
                    throw DocumentSaveError.unknown
                }
            }
            
            // Inform callback
            object.didSave()
            return object
        })
    }
    
    
    /// Insert an array of objects into the collection.
    /// Note: If the oid of the object is not added to the map, it will generate a new ObjectId.
    ///
    /// - Parameter objects: The objects to save.
    /// - Returns: An EventLoopFuture that returns the updated object.
    /// - Throws: Either an error with mapping the object or a `MongoKitten` error.
    public func insert<T: MongoEncodable>(_ objects: [T]) throws -> EventLoopFuture<[T]> {
        var objects = objects
        
        // Inform callbacks
        for (index, object) in objects.enumerated() {
            var object = object
            try object.willSave()
            objects[index] = object
        }
        
        let documents = try objects.map({ try $0.makeDocument() })
        return self.insert(documents: documents).thenThrowing({ reply in
            guard reply.isSuccessful else {
                if let message = reply.errorMessage {
                    throw DocumentSaveError.recievedMessage(message)
                } else {
                    throw DocumentSaveError.unknown
                }
            }
            
            // Inform callbacks
            for (index, object) in objects.enumerated() {
                var object = object
                object.didSave()
                objects[index] = object
            }
            
            return objects
        })
    }
    
    /// Insert or update an object in the collection. It uses the oid to save or update this object.
    ///
    /// - Parameter object: The object to insert or update.
    /// - Returns: An EventLoopFuture that returns the updated object.
    /// - Throws: Either an error with mapping the object or a `MongoKitten` error.
    public func upsert<T: MongoEncodable>(_ object: T) throws -> EventLoopFuture<T> {
        var object = object
        
        // Inform callback
        try object.willSave()
        
        let document = try object.makeDocument()
        return upsert(where: "_id" == object._id, to: document).thenThrowing({ reply in
            guard reply.isSuccessful else {
                throw DocumentSaveError.unknown
            }
            
            // Inform callback
            object.didSave()
            return object
        })
    }
    
    /// Update an object in the collection. The full object is replaced in the collection using its oid.
    ///
    /// - Parameter object: The object to update. This object must have an oid that is already saved in the database.
    /// - Returns: An EventLoopFuture that returns the updated object.
    /// - Throws: Either an error with mapping the object or a `MongoKitten` error.
    public func update<T: MongoEncodable>(_ object: T) throws -> EventLoopFuture<T> {
        var object = object
        
        // Inform callback
        try object.willSave()
        
        let document = try object.makeDocument()
        return update(where: "_id" == object._id, to: document).thenThrowing({ reply in
            guard reply.isSuccessful else {
                throw DocumentSaveError.unknown
            }
            
            // Inform callback
            object.didSave()
            return object
        })
    }

    
    /// Updates only the specified keys leaving everything else alone.
    /// NOTE: The object returned is not reloaded. therefore any fields that are changed but not specified
    /// in `valuesForKeys` may not reflect what the database contains.
    ///
    /// - Parameters:
    ///   - object: The object to update.
    ///   - keys: The keys to update on the object.
    /// - Returns: A new future with the updated object.
    /// - Throws: Either an error with mapping the object or a `MongoKitten` error.
    public func update<O: MongoObject>(object: O, valuesForKeys keys: [String]) throws -> EventLoopFuture<O> {
        var object = object
        
        // Inform callback
        try object.willSave()
        
        let document = try object.makeDocument()
        var values: [String: Primitive?] = [:]
        
        for key in keys {
            values[key] = document[key]
        }
        
        // Update the parameters specified
        return self.update(where: "_id" == object._id, setting: values, multiple: false).thenThrowing({ updateReply in
            guard updateReply.isSuccessful else {
                throw DocumentSaveError.recievedMessage(updateReply.localizedDescription)
            }
            
            // Inform callback
            object.didSave()
            return object
        })
    }
    
    // MARK: - Required
    
    /// Return the first object in the collection for the given query.
    ///
    /// - Parameter query: The query used to find the object.
    /// - Returns: An EventLoopFuture that returns the document.
    public func required(where query: Query) -> EventLoopFuture<Document> {
        let future = self.findOne(query)
        
        return future.thenThrowing( { document in
            guard let document = document else {
                throw DocumentLoadError.documentNotFound
            }
            
            return document
        })
    }
    
    /// Returns the first object with the given oid.
    ///
    /// - Parameter oid: The ObjectId identifying the object we want to retrive.
    /// - Returns: An EventLoopFuture that returns the document.
    public func required(oid: ObjectId) -> EventLoopFuture<Document> {
        return required(where: "_id" == oid)
    }
    
    /// Returns the first object with the given oid as a hex string.
    ///
    /// - Parameter id: The ObjectId in a string (hex) format.
    /// - Returns: An EventLoopFuture that returns the document.
    /// - Throws: Throws when the ObjectID cannot be created using the hex string or a `MongoKitten` error
    public func required(oid: String) throws -> EventLoopFuture<Document> {
        let oid = try ObjectId(oid)
        return required(oid: oid)
    }
    
    /// First document converted to an object.
    ///
    /// - Parameters:
    ///   - query: The query used to find the object.
    ///   - to: The type of object to decode.
    /// - Returns: The decoded object.
    public func required<T: MongoDecodable>(where query: Query, type: T.Type) -> EventLoopFuture<T> {
        return required(where: query).decode(to: type)
    }
    
    /// First document converted to an object.
    ///
    /// - Parameters:
    ///   - oid: The object id.
    ///   - to: The type of object to decode.
    /// - Returns: The decoded object.
    public func required<T: MongoDecodable>(oid: ObjectId, type: T.Type) -> EventLoopFuture<T> {
        return required(oid: oid).decode(to: type)
    }
    
    /// First document converted to an object.
    ///
    /// - Parameters:
    ///   - oid: The object id in hex string format.
    ///   - to: The type of object to decode.
    /// - Returns: The decoded object.
    public func required<T: MongoDecodable>(oid: String, type: T.Type) throws -> EventLoopFuture<T> {
        return try required(oid: oid).decode(to: type)
    }
    
    // MARK: - Find One
    
    /// First document converted to an object.
    ///
    /// - Parameters:
    ///   - query: The query used to find the object.
    ///   - to: The type of object to decode.
    /// - Returns: The decoded object.
    public func findOne<T: MongoDecodable>(where query: Query, type: T.Type) -> EventLoopFuture<T?> {
        return findOne(query).decode(to: type)
    }
    
    /// First document converted to an object.
    ///
    /// - Parameters:
    ///   - oid: The object id.
    ///   - to: The type of object to decode.
    /// - Returns: The decoded object.
    public func findOne<T: MongoDecodable>(oid: ObjectId, type: T.Type) -> EventLoopFuture<T?> {
        return findOne(where: "_id" == oid, type: type)
    }
    
    /// First document converted to an object.
    ///
    /// - Parameters:
    ///   - oid: The object id in hex string format.
    ///   - to: The type of object to decode.
    /// - Returns: The decoded object.
    public func findOne<T: MongoDecodable>(oid: String, type: T.Type) throws -> EventLoopFuture<T?> {
        let objectId = try ObjectId(oid)
        return findOne(oid: objectId, type: type)
    }
    
    // MARK: - Destroy
    
    /// Destroy all objects for the given ObjectId on the collection.
    ///
    /// - Parameter oid: The ObjectId identifying the object we want to delete.
    /// - Returns: Returns the EventLoopFuture that returns the number of objects deleted.
    public func destroy(oid: ObjectId) -> EventLoopFuture<Int> {
        return self.deleteAll(where: "_id" == oid)
    }
    
    /// Destroy an object for the given oid in hex string format on the collection.
    ///
    /// - Parameter id: The ObjectId in hex string format identifying the object we want to delete.
    /// - Returns: Returns the EventLoopFuture that returns the number of objects deleted.
    /// - Throws: Throws if the hex string cannot be converted to an ObjectId.
    public func destroy(oid: String) throws -> EventLoopFuture<Int> {
        let objectId = try ObjectId(oid)
        return destroy(oid: objectId)
    }
    
    /// Destroy the given object on the collection.
    ///
    /// - Parameter object: The object we want to destroy.
    /// - Returns: Returns the EventLoopFuture that returns the number of objects deleted.
    public func destroy<T: MongoObject>(_ object: T) -> EventLoopFuture<Int> {
        return destroy(oid: object._id)
    }
    
    // MARK: - Exists
    
    /// Check if the object exists in the collection.
    ///
    /// - Parameter query: The query to search for the object.
    /// - Returns: Returns the EventLoopFuture that returns a boolean. This boolean is true if the object exists.
    public func exists(where query: Query) -> EventLoopFuture<Bool> {
        let future = self.count(query)
        
        return future.thenThrowing({ count in
            return count > 0
        })
    }
    
    /// Check if the object exists in the collection for the given oid identifier.
    ///
    /// - Parameter oid: The ObjectId identifying the object.
    /// - Returns: Returns the EventLoopFuture that returns a boolean. This boolean is true if the object exists.
    public func exists(oid: ObjectId) -> EventLoopFuture<Bool> {
        return exists(where: "_id" == oid)
    }
    
    /// Check if the object exists in the collection for the given oid hex string identifier.
    ///
    /// - Parameter oid: The ObjectId identifying the object.
    /// - Returns: Returns the EventLoopFuture that returns a boolean. This boolean is true if the object exists.
    /// - Throws: Throws if the hex string cannot be converted to an ObjectId.
    public func exists(oid: String) throws -> EventLoopFuture<Bool> {
        let objectId = try ObjectId(oid)
        return exists(oid: objectId)
    }
    
    /// Check if the given object is saved in the collection using only its oid.
    ///
    /// - Parameter object: The object to get the oid from.
    /// - Returns: Returns the EventLoopFuture that returns a boolean. This boolean is true if the object exists.
    public func exists<T: MongoObject>(_ object: T) -> EventLoopFuture<Bool> {
        return exists(oid: object._id)
    }
}
