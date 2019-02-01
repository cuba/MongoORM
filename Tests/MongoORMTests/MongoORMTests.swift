import XCTest
import MongoKitten
import MapCodableKit
@testable import MongoORM

final class MongoORMTests: XCTestCase {
    private var _database: Database?
    
    struct TestUser: MongoObject, MapCodable {
        let oid: ObjectId
        var email: String
        var password: String
        
        init(email: String, password: String) {
            self.oid = ObjectId()
            self.email = email
            self.password = password
        }
        
        init(map: Map) throws {
            self.oid        = try map.oid()
            self.email      = try map.value(from: "email")
            self.password   = try map.value(from: "password")
        }
        
        func fill(map: Map) throws {
            try map.add(oid)
            try map.add(email, for: "email")
            try map.add(password, for: "password")
        }
    }
    
    override func tearDown() {
        XCTAssertNoThrow(try self.usersCollection().drop())
    }
    
    func testInsertDocument() {
        // Given
        let createdUser = TestUser(email: "someone@example.com", password: "foobar123")
        
        do {
            // When
            let collection = try self.usersCollection()
            XCTAssertNoThrow(try collection.insert(createdUser).wait())
            
            // Then
            let document = try collection.required(oid: createdUser.oid).wait()
            let loadedUser = try document.decode(to: TestUser.self)
            XCTAssertEqual(createdUser.oid, loadedUser.oid)
            XCTAssertEqual(createdUser.email, loadedUser.email)
            XCTAssertEqual(createdUser.password, loadedUser.password)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testUpsertDocument() {
        // Given
        let createdUser = TestUser(email: "someone@example.com", password: "foobar123")
        
        do {
            // When
            let collection = try self.usersCollection()
            XCTAssertNoThrow(try collection.upsert(createdUser).wait())
            
            // Then
            let document = try collection.required(oid: createdUser.oid).wait()
            let loadedUser = try document.decode(to: TestUser.self)
            XCTAssertEqual(createdUser.oid, loadedUser.oid)
            XCTAssertEqual(createdUser.email, loadedUser.email)
            XCTAssertEqual(createdUser.password, loadedUser.password)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testUpdateDocument() {
        // Given
        var createdUser = TestUser(email: "someone@example.com", password: "foobar123")
        
        do {
            // When
            let collection = try self.usersCollection()
            XCTAssertNoThrow(try collection.upsert(createdUser).wait())
            createdUser.password = "foobar345"
            XCTAssertNoThrow(try collection.update(createdUser).wait())
            
            // Then
            let document = try collection.required(oid: createdUser.oid).wait()
            let loadedUser = try document.decode(to: TestUser.self)
            XCTAssertEqual(try collection.count().wait(), 1)
            XCTAssertEqual(createdUser.oid, loadedUser.oid)
            XCTAssertEqual(createdUser.email, loadedUser.email)
            XCTAssertEqual(createdUser.password, loadedUser.password)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testInsertDocuments() {
        // Given
        let createdUsers = [
            TestUser(email: "someone1@example.com", password: "foobar123"),
            TestUser(email: "someone2@example.com", password: "foobar123")
        ]
        
        do {
            // When
            let collection = try self.usersCollection()
            XCTAssertNoThrow(try collection.insert(createdUsers).wait())
            
            // Then
            XCTAssertEqual(try collection.count().wait(), 2)
            var loadedUsers: [TestUser] = []
            
            try collection.find().forEach(handler: { document in
                let loadedUser = try document.decode(to: TestUser.self)
                loadedUsers.append(loadedUser)
            }).wait()
            
            XCTAssertEqual(loadedUsers.count, 2)
            
            for createdUser in createdUsers {
                let loadedUser = loadedUsers.first(for: createdUser.oid)
                
                XCTAssertEqual(createdUser.oid, loadedUser?.oid)
                XCTAssertEqual(createdUser.email, loadedUser?.email)
                XCTAssertEqual(createdUser.password, loadedUser?.password)
            }
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testFirstWithQuery() {
        // Given
        let createdUsers = [
            TestUser(email: "someone1@example.com", password: "foobar1"),
            TestUser(email: "someone2@example.com", password: "foobar2"),
            TestUser(email: "someone3@example.com", password: "foobar3")
        ]
        
        do {
            // When
            let collection = try self.usersCollection()
            XCTAssertNoThrow(try collection.insert(createdUsers).wait())
            
            // Then
            XCTAssertEqual(try collection.count().wait(), 3)
            
            let createdUser = createdUsers[1]
            let loadedUser = try collection.required(where: "_id" == createdUser.oid, type: TestUser.self).wait()
            XCTAssertEqual(createdUser.oid, loadedUser.oid)
            XCTAssertEqual(createdUser.email, loadedUser.email)
            XCTAssertEqual(createdUser.password, loadedUser.password)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testFirstWithStringId() {
        // Given
        let createdUsers = [
            TestUser(email: "someone1@example.com", password: "foobar1"),
            TestUser(email: "someone2@example.com", password: "foobar2"),
            TestUser(email: "someone3@example.com", password: "foobar3")
        ]
        
        do {
            // When
            let collection = try self.usersCollection()
            XCTAssertNoThrow(try collection.insert(createdUsers).wait())
            
            // Then
            XCTAssertEqual(try collection.count().wait(), 3)
            
            let createdUser = createdUsers[1]
            let loadedUser = try collection.required(oid: createdUser.oid.hexString, type: TestUser.self).wait()
            XCTAssertEqual(createdUser.oid, loadedUser.oid)
            XCTAssertEqual(createdUser.email, loadedUser.email)
            XCTAssertEqual(createdUser.password, loadedUser.password)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testFirstWithObjectId() {
        // Given
        let createdUsers = [
            TestUser(email: "someone1@example.com", password: "foobar1"),
            TestUser(email: "someone2@example.com", password: "foobar2"),
            TestUser(email: "someone3@example.com", password: "foobar3")
        ]
        
        do {
            // When
            let collection = try self.usersCollection()
            XCTAssertNoThrow(try collection.insert(createdUsers).wait())
            
            // Then
            XCTAssertEqual(try collection.count().wait(), 3)
            
            let createdUser = createdUsers[1]
            let loadedUser = try collection.required(oid: createdUser.oid, type: TestUser.self).wait()
            XCTAssertEqual(createdUser.oid, loadedUser.oid)
            XCTAssertEqual(createdUser.email, loadedUser.email)
            XCTAssertEqual(createdUser.password, loadedUser.password)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testFirstWithQuery_NotFound() {
        // Given
        let objectId = ObjectId()
        
        do {
            // When
            let collection = try self.usersCollection()
            let _ = try collection.required(where: "_id" == objectId, type: TestUser.self).wait()
            
            // Not
            XCTFail("Should have thrown error")
        } catch let error {
            // Then
            guard let loadError = error as? DocumentLoadError else {
                XCTFail("Expecting `DocumentLoadError`")
                return
            }
            
            switch loadError {
            case .documentNotFound:
                break;
            default:
                XCTFail("Unexpected error type: \(loadError)")
            }
        }
    }
    
    func testFirstWithStringId_NotFound() {
        // Given
        let objectId = ObjectId()
        
        do {
            // When
            let collection = try self.usersCollection()
            let _ = try collection.required(oid: objectId.hexString, type: TestUser.self).wait()
            
            // Not
            XCTFail("Should have thrown error")
        } catch let error {
            // Then
            guard let loadError = error as? DocumentLoadError else {
                XCTFail("Expecting `DocumentLoadError`")
                return
            }
            
            switch loadError {
            case .documentNotFound:
                break;
            default:
                XCTFail("Unexpected error type: \(loadError)")
            }
        }
    }
    
    func testFirstWithObjectId_NotFound() {
        // Given
        let objectId = ObjectId()
        
        do {
            // When
            let collection = try self.usersCollection()
            let _ = try collection.required(oid: objectId, type: TestUser.self).wait()
            
            // Not
            XCTFail("Should have thrown error")
        } catch let error {
            // Then
            guard let loadError = error as? DocumentLoadError else {
                XCTFail("Expecting `DocumentLoadError`")
                return
            }
            
            switch loadError {
            case .documentNotFound:
                break;
            default:
                XCTFail("Unexpected error type: \(loadError)")
            }
        }
    }
    
    func testFindOneWithQuery() {
        // Given
        let createdUsers = [
            TestUser(email: "someone1@example.com", password: "foobar1"),
            TestUser(email: "someone2@example.com", password: "foobar2"),
            TestUser(email: "someone3@example.com", password: "foobar3")
        ]
        
        do {
            // When
            let collection = try self.usersCollection()
            XCTAssertNoThrow(try collection.insert(createdUsers).wait())
            
            // Then
            XCTAssertEqual(try collection.count().wait(), 3)
            
            let createdUser = createdUsers[1]
            let loadedUser = try collection.findOne(where: "_id" == createdUser.oid, type: TestUser.self).wait()
            XCTAssertEqual(createdUser.oid, loadedUser?.oid)
            XCTAssertEqual(createdUser.email, loadedUser?.email)
            XCTAssertEqual(createdUser.password, loadedUser?.password)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testFindOneWithStringId() {
        // Given
        let createdUsers = [
            TestUser(email: "someone1@example.com", password: "foobar1"),
            TestUser(email: "someone2@example.com", password: "foobar2"),
            TestUser(email: "someone3@example.com", password: "foobar3")
        ]
        
        do {
            // When
            let collection = try self.usersCollection()
            XCTAssertNoThrow(try collection.insert(createdUsers).wait())
            
            // Then
            XCTAssertEqual(try collection.count().wait(), 3)
            
            let createdUser = createdUsers[1]
            let loadedUser = try collection.findOne(oid: createdUser.oid.hexString, type: TestUser.self).wait()
            XCTAssertEqual(createdUser.oid, loadedUser?.oid)
            XCTAssertEqual(createdUser.email, loadedUser?.email)
            XCTAssertEqual(createdUser.password, loadedUser?.password)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testFindOneWithObjectId() {
        // Given
        let createdUsers = [
            TestUser(email: "someone1@example.com", password: "foobar1"),
            TestUser(email: "someone2@example.com", password: "foobar2"),
            TestUser(email: "someone3@example.com", password: "foobar3")
        ]
        
        do {
            // When
            let collection = try self.usersCollection()
            XCTAssertNoThrow(try collection.insert(createdUsers).wait())
            
            // Then
            XCTAssertEqual(try collection.count().wait(), 3)
            
            let createdUser = createdUsers[1]
            let loadedUser = try collection.findOne(oid: createdUser.oid, type: TestUser.self).wait()
            XCTAssertEqual(createdUser.oid, loadedUser?.oid)
            XCTAssertEqual(createdUser.email, loadedUser?.email)
            XCTAssertEqual(createdUser.password, loadedUser?.password)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testFindOneWithQuery_NotFound() {
        // Given
        let objectId = ObjectId()
        
        do {
            // When
            let collection = try self.usersCollection()
            let loadedUser = try collection.findOne(where: "_id" == objectId, type: TestUser.self).wait()
            
            // Then
            XCTAssertNil(loadedUser)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testFindOneWithStringId_NotFound() {
        // Given
        let objectId = ObjectId()
        
        do {
            // When
            let collection = try self.usersCollection()
            let loadedUser = try collection.findOne(oid: objectId.hexString, type: TestUser.self).wait()
            
            // Then
            XCTAssertNil(loadedUser)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testFindOneWithObjectId_NotFound() {
        // Given
        let objectId = ObjectId()
        
        do {
            // When
            let collection = try self.usersCollection()
            let loadedUser = try collection.findOne(oid: objectId, type: TestUser.self).wait()
            
            // Then
            XCTAssertNil(loadedUser)
        } catch {
            XCTFail("Should not throw")
        }
    }

    func testDeleteDocument() {
        // Given
        let createdUser = TestUser(email: "someone@example.com", password: "foobar123")
        
        do {
            // When
            let collection = try self.usersCollection()
            XCTAssertNoThrow(try collection.upsert(createdUser).wait())
            XCTAssertEqual(try collection.count().wait(), 1)
            
            // Then
            XCTAssertNoThrow(try collection.destroy(createdUser).wait())
            XCTAssertEqual(try collection.count().wait(), 0)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testDeleteDocumentByStringId() {
        // Given
        let createdUser = TestUser(email: "someone@example.com", password: "foobar123")
        
        do {
            // When
            let collection = try self.usersCollection()
            XCTAssertNoThrow(try collection.upsert(createdUser).wait())
            XCTAssertEqual(try collection.count().wait(), 1)
            
            // Then
            XCTAssertNoThrow(try collection.destroy(oid: createdUser.oid.hexString).wait())
            XCTAssertEqual(try collection.count().wait(), 0)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testDeleteDocumentByObjectId() {
        // Given
        let createdUser = TestUser(email: "someone@example.com", password: "foobar123")
        
        do {
            // When
            let collection = try self.usersCollection()
            XCTAssertNoThrow(try collection.upsert(createdUser).wait())
            XCTAssertEqual(try collection.count().wait(), 1)
            
            // Then
            XCTAssertNoThrow(try collection.destroy(oid: createdUser.oid).wait())
            XCTAssertEqual(try collection.count().wait(), 0)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testContainsWithQuery() {
        // Given
        let createdUser = TestUser(email: "someone@example.com", password: "foobar123")
        
        do {
            // When
            let collection = try self.usersCollection()
            XCTAssertEqual(try collection.exists(where: "_id" == createdUser.oid).wait(), false)
            XCTAssertNoThrow(try collection.insert(createdUser).wait())
            XCTAssertEqual(try collection.exists(where: "_id" == createdUser.oid).wait(), true)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    private func database() throws -> Database {
        if let database = self._database {
            return database
        } else {
            let database = try Database.synchronousConnect("mongodb://localhost/mongo_orm_tests")
            self._database = database
            return database
        }
    }

    func usersCollection() throws -> MongoKitten.Collection {
        return try self.database().usersCollection
    }
}

extension Database {
    
    var usersCollection: MongoKitten.Collection {
        return self["users"]
    }
}
