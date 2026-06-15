import CoreFP
import FPMacros
import Testing

// MARK: - Fixtures

@Witness
fileprivate protocol Greeter {
    func greet(name: String) -> String
    var enthusiasm: Int { get }
}

fileprivate struct LoudGreeter: Greeter, Sendable {
    let enthusiasm: Int
    func greet(name: String) -> String { "HELLO \(name)" + String(repeating: "!", count: enthusiasm) }
}

fileprivate enum RepoError: Error, Equatable { case notFound }

@Witness
fileprivate protocol Repository<Item> {
    associatedtype Item
    associatedtype Failure: Error
    func fetch(id: String) async -> Result<Item, Failure>
    var count: Int { get }
}

fileprivate struct MemoryRepo: Repository, Sendable {
    let store: [String: Int]
    func fetch(id: String) async -> Result<Int, RepoError> {
        store[id].map(Result.success) ?? .failure(.notFound)
    }
    var count: Int { store.count }
}

@Witness
fileprivate protocol Finder {
    func find(id: Int) -> String
    func find(name: String) -> String
}

@Witness
fileprivate protocol Animal {
    func sound() -> String
}

@Witness
fileprivate protocol Pet: Animal {
    var name: String { get }
}

fileprivate struct Dog: Pet, Sendable {
    let name: String
    func sound() -> String { "woof" }
}

@Witness
fileprivate protocol Printer {
    func print<T: CustomStringConvertible>(_ value: T)
}

@Witness
fileprivate protocol Counter {
    var value: Int { get set }
    func bump()
}

fileprivate final class LiveCounter: Counter, @unchecked Sendable {
    var value: Int = 0
    func bump() { value += 1 }
}

private final class Cell<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}

// MARK: - Tests

@Suite("@Witness")
struct WitnessTests {
    @Test func memberwiseInit() {
        let w = GreeterWitness(greet: { "hi \($0)" }, enthusiasm: { 3 })
        #expect(w.greet("bob") == "hi bob")
        #expect(w.enthusiasm() == 3)
    }

    @Test func fromInstanceConversion() {
        let w = LoudGreeter(enthusiasm: 2).witness
        #expect(w.greet("al") == "HELLO al!!")
        #expect(w.enthusiasm() == 2)
    }

    @Test func associatedTypesAndAsync() async {
        let w = MemoryRepo(store: ["a": 1]).witness   // RepositoryWitness<Int, RepoError>
        #expect(w.count() == 1)
        let hit = await w.fetch("a")
        #expect(hit == .success(1))
        let miss = await w.fetch("b")
        #expect(miss == .failure(.notFound))
    }

    @Test func overloadDisambiguation() {
        let w = FinderWitness(findWithId: { "id\($0)" }, findWithName: { "name-\($0)" })
        #expect(w.findWithId(7) == "id7")
        #expect(w.findWithName("x") == "name-x")
    }

    @Test func inheritanceComposition() {
        let w = Dog(name: "Rex").witness   // PetWitness { name thunk, animal: AnimalWitness }
        #expect(w.name() == "Rex")
        #expect(w.animal.sound() == "woof")
    }

    @Test func genericMethodErasedToExistential() {
        let box = Box()
        let w = PrinterWitness(print: { box.value = $0.description })
        w.print(42)
        #expect(box.value == "42")
    }

    @Test func settablePropertyFromReferenceConformer() {
        let live = LiveCounter()
        let w = live.witness   // gated to AnyObject — the class conformer gets `.witness`
        w.bump()
        w.setValue(10)
        #expect(w.value() == 10)
        #expect(live.value == 10)   // mutates through the live instance
    }

    @Test func settablePropertyViaMemberwiseInit() {
        let cell = Cell(0)
        let w = CounterWitness(bump: { cell.value += 1 }, value: { cell.value }, setValue: { cell.value = $0 })
        w.setValue(5)
        w.bump()
        #expect(w.value() == 6)
    }

    @Test func witnessIsSendable() async {
        // A witness must cross an isolation boundary.
        let w = LoudGreeter(enthusiasm: 1).witness
        let result = await Task { w.greet("x") }.value
        #expect(result == "HELLO x!")
    }
}

private final class Box: @unchecked Sendable {
    var value: String = ""
}
