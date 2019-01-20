import XCTest
@testable import MongoORM

final class MongoORMTests: XCTestCase {
    private let connectionPool = ConnectionPool(url: URL(string: "mongodb://localhost/mongo_orm_tests")!)
    
    func mongoORM() throws -> MongoORM<TestUser> {
        return try connectionPool.orm(for: TestUser.self, collectionName: "users")
    }
    
    override func tearDown() {
        XCTAssertNoThrow(try mongoORM().collection.drop())
    }
    
    struct TestUser: MongoDocument {
        let oid: ObjectId
        var email: String
        var password: String
        
        init(email: String, password: String) {
            self.oid = ObjectId()
            self.email = email
            self.password = password
        }
        
        init(map: Map) throws {
            self.oid        = try map.value(from: "_id")
            self.email      = try map.value(from: "email")
            self.password   = try map.value(from: "password")
        }
        
        func fill(map: Map) throws {
            try map.add(email, for: "email")
            try map.add(password, for: "password")
        }
    }
    
    func testLoadDocument() {
        // Given
        let createdUser = TestUser(email: "someone@example.com", password: "foobar123")
        
        // When
        XCTAssertNoThrow(try mongoORM().save(createdUser))
        
        do {
            // Then
            let loadedUser = try mongoORM().first(oid: createdUser.oid)
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
        XCTAssertNoThrow(try mongoORM().save(createdUser))
        
        // When
        createdUser.password = "foobar345"
        XCTAssertNoThrow(try mongoORM().save(createdUser))
        
        do {
            let loadedUsers = try mongoORM().all()
            XCTAssertEqual(loadedUsers.successes.count, 1)
            XCTAssertEqual(loadedUsers.successes.first?.oid, createdUser.oid)
            XCTAssertEqual(loadedUsers.successes.first?.password, createdUser.password)
            XCTAssertEqual(loadedUsers.successes.first?.email, createdUser.email)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testDeleteDocument() {
        // Given
        var createdUser = TestUser(email: "someone@example.com", password: "foobar123")
        XCTAssertNoThrow(try mongoORM().save(createdUser))
        
        // When
        createdUser.password = "foobar345"
        XCTAssertNoThrow(try mongoORM().destroy(createdUser))
        
        do {
            // Then
            let loadedUsers = try mongoORM().all()
            XCTAssertEqual(loadedUsers.successes.count, 0)
        } catch {
            XCTFail("Should not throw")
        }
    }
}
