// SPDX-License-Identifier: Apache-2.0
import CoreFP
import FPMacros
import Testing

// MARK: - Fixtures

@Mock
fileprivate protocol Service {
    func fetch(id: String) -> [Int]
    func save(_ value: Int) async throws
    var isReady: Bool { get }
}

@Mock
fileprivate protocol Finder2 {
    func find(id: Int) -> String
    func find(name: String) -> String
}

@Mock
fileprivate protocol Store2<Item> {
    associatedtype Item
    func get(_ key: String) -> Item?
    var all: [Item] { get }
}

@Mock
fileprivate protocol Encoder2 {
    func encode<T: CustomStringConvertible>(_ value: T) -> String
}

@Mock
fileprivate protocol Settings2 {
    var volume: Int { get set }
}

private final class Cell<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}

// MARK: - Tests

@Suite("@Mock")
struct MockTests {
    @Test func overrideAndDelegate() async throws {
        let mock = ServiceMock(
            fetch: { [$0.count] },
            save: { _ in },
            isReady: { true }
        )
        #expect(mock.fetch(id: "abc") == [3])
        try await mock.save(5)
        #expect(mock.isReady == true)
    }

    @Test func partialOverrideLeavesOthersDefaulted() {
        // Only `isReady` is overridden; `fetch`/`save` default to `fail(...)` but are never called.
        let mock = ServiceMock(isReady: { false })
        #expect(mock.isReady == false)
    }

    @Test func overloadDisambiguation() {
        let mock = Finder2Mock(findWithId: { "id\($0)" }, findWithName: { "name-\($0)" })
        #expect(mock.find(id: 7) == "id7")
        #expect(mock.find(name: "x") == "name-x")
    }

    @Test func associatedTypes() {
        let mock = Store2Mock<Int>(get: const(42), all: { [1, 2, 3] })
        #expect(mock.get("x") == 42)
        #expect(mock.all == [1, 2, 3])
    }

    @Test func genericMethodErased() {
        let mock = Encoder2Mock(encode: { $0.description })
        #expect(mock.encode(42) == "42")
    }

    @Test func settableProperty() {
        let store = Cell(0)
        var mock = Settings2Mock(volume: { store.value }, setVolume: { store.value = $0 })
        mock.volume = 11
        #expect(store.value == 11)
        #expect(mock.volume == 11)
    }
}
