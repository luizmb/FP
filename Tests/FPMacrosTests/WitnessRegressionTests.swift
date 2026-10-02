// SPDX-License-Identifier: Apache-2.0
import CoreFP
import FPMacros
import Testing

// MARK: - Fixtures

fileprivate enum LoadError: Error, Equatable {
    case missing
}

/// Marker / stdlib parents are satisfied by `Base`, not composed into the witness.
@Witness
fileprivate protocol Named: Equatable, CustomStringConvertible {
    var name: String { get }
}

fileprivate struct Person: Named, Sendable {
    let name: String
    var description: String { name }
}

/// A `Sendable & AnyObject` composition: class-bound, so the setter writes through `instance` directly.
@Witness
fileprivate protocol Ticker: Sendable & AnyObject {
    var ticks: Int { get set }
    func tick()
}

fileprivate final class LiveTicker: Ticker, @unchecked Sendable {
    var ticks = 0
    func tick() { ticks += 1 }
}

/// A settable parent composes into a class-bound child.
@Witness
fileprivate protocol Volume {
    var level: Int { get set }
}

@Witness
fileprivate protocol Speaker: AnyObject, Volume {
    func play() -> String
}

fileprivate final class Radio: Speaker, @unchecked Sendable {
    var level = 1
    func play() -> String { "playing at \(level)" }
}

@Witness
fileprivate protocol Loader {
    func describe(_ value: some CustomStringConvertible) -> String
    func load(id: Int) throws(LoadError) -> String
    var cached: String { get throws(LoadError) }
    var latest: Int { get async throws }
    func find(id: Int) -> String
    func find(id: String) -> String
}

fileprivate struct MemoryLoader: Loader, Sendable {
    let store: [Int: String]
    func describe(_ value: some CustomStringConvertible) -> String { "<\(value)>" }
    func load(id: Int) throws(LoadError) -> String {
        guard let value = store[id] else { throw .missing }
        return value
    }

    var cached: String { get throws(LoadError) { try load(id: 1) } }
    var latest: Int { get async throws { store.count } }
    func find(id: Int) -> String { "int \(id)" }
    func find(id: String) -> String { "string \(id)" }
}

// MARK: - Tests

@Suite("@Witness — regressions")
struct WitnessRegressionTests {
    @Test func marker_parents_are_not_composed() {
        let w = Person(name: "Ann").witness
        #expect(w.name() == "Ann")
    }

    @Test func class_bound_composition_writes_through_instance() {
        let live = LiveTicker()
        let w = live.witness
        w.tick()
        w.setTicks(10)
        w.tick()
        #expect(live.ticks == 11)
        #expect(w.ticks() == 11)
    }

    @Test func settable_parent_composes_into_class_bound_child() {
        let radio = Radio()
        let w = radio.witness
        w.volume.setLevel(7)
        #expect(radio.level == 7)
        #expect(w.play() == "playing at 7")
    }

    @Test func some_parameter_is_erased() {
        let w = MemoryLoader(store: [:]).witness
        #expect(w.describe(42) == "<42>")
    }

    @Test func typed_throws_is_preserved() {
        let w = MemoryLoader(store: [1: "one"]).witness
        // A `throws(LoadError)` closure only accepts the call if the field kept the typed `throws(LoadError)`.
        let hit: Result<String, LoadError> = Result { () throws(LoadError) in try w.load(1) }
        let miss: Result<String, LoadError> = Result { () throws(LoadError) in try w.load(2) }
        #expect(hit == .success("one"))
        #expect(miss == .failure(.missing))
        let cached: Result<String, LoadError> = Result { () throws(LoadError) in try w.cached() }
        #expect(cached == .success("one"))
    }

    @Test func async_throwing_property_forwards() async throws {
        let w = MemoryLoader(store: [1: "one", 2: "two"]).witness
        let latest = try await w.latest()
        #expect(latest == 2)
    }

    @Test func same_label_overloads_fall_back_to_types() {
        let w = MemoryLoader(store: [:]).witness
        #expect(w.findWithIdInt(1) == "int 1")
        #expect(w.findWithIdString("a") == "string a")
    }
}

@Suite("@Witness — diagnostics")
struct WitnessDiagnosticTests {
    @Test func rejects_private_protocol() {
        assertDiagnostic(
            """
            @Witness
            private protocol P {
                func f()
            }
            """,
            expandsTo: """
            private protocol P {
                func f()
            }
            """,
            message: privateHostMessage("@Witness", "protocols")
        )
    }

    @Test func rejects_self() {
        assertDiagnostic(
            """
            @Witness
            protocol P {
                func merge(_ other: Self) -> Int
            }
            """,
            expandsTo: """
            protocol P {
                func merge(_ other: Self) -> Int
            }
            """,
            message: "@Witness can't handle requirements that mention `Self` — inside the generated struct `Self` "
                + "would mean the witness, not the conforming type.",
            line: 3,
            column: 5
        )
    }

    @Test func rejects_variadics() {
        assertDiagnostic(
            """
            @Witness
            protocol P {
                func sum(_ values: Int...) -> Int
            }
            """,
            expandsTo: """
            protocol P {
                func sum(_ values: Int...) -> Int
            }
            """,
            message: "@Witness can't handle variadic parameters — a closure can't forward an array back into a "
                + "variadic call. Take an array parameter instead.",
            line: 3,
            column: 14
        )
    }

    @Test func rejects_rethrows() {
        assertDiagnostic(
            """
            @Witness
            protocol P {
                func run(_ body: () throws -> Void) rethrows
            }
            """,
            expandsTo: """
            protocol P {
                func run(_ body: () throws -> Void) rethrows
            }
            """,
            message: "@Witness can't handle `rethrows` requirements — a stored closure can't be `rethrows`. "
                + "Declare the requirement `throws` (or with a typed `throws(E)`).",
            line: 3,
            column: 5
        )
    }

    @Test func rejects_unsound_generic_erasure() {
        for signature in ["func pair<T: Equatable>(_ a: T, _ b: T)", "func all<T: Equatable>(_ values: [T])"] {
            assertDiagnostic(
                """
                @Witness
                protocol P {
                    \(signature)
                }
                """,
                expandsTo: """
                protocol P {
                    \(signature)
                }
                """,
                message: "@Witness can only erase generic parameter 'T' to `any` when it is the whole type of exactly "
                    + "one parameter (not nested like `[T]`, repeated, or constrained by a `where` same-type requirement).",
                line: 3,
                column: 5
            )
        }
    }

    @Test func rejects_nested_some() {
        assertDiagnostic(
            """
            @Witness
            protocol P {
                func all(_ values: [some Equatable])
            }
            """,
            expandsTo: """
            protocol P {
                func all(_ values: [some Equatable])
            }
            """,
            message: "@Witness can only erase `some P` when it is the parameter's whole type; a nested `some` "
                + "(e.g. `[some P]`, `(some P) -> Void`) can't be lowered to an existential.",
            line: 3,
            column: 14
        )
    }

    @Test func rejects_generic_parent() {
        assertDiagnostic(
            """
            @Witness
            protocol P: Collection<Int> {
                func f()
            }
            """,
            expandsTo: """
            protocol P: Collection<Int> {
                func f()
            }
            """,
            message: "@Witness can't compose parent protocol 'Collection<Int>': it is generic or has associated "
                + "types, so its witness can't be named here. Flatten the requirements you need into this protocol.",
            line: 2,
            column: 10
        )
    }

    @Test func rejects_indistinguishable_overloads() {
        let expansion = expand("""
        @Witness
        protocol P {
            func make() -> Int
            func make() -> String
        }
        """)
        #expect(expansion.diagnostics.count == 2)
        #expect(expansion.diagnostics.allSatisfy { $0.hasPrefix("@Witness can't give 'make' a unique name") })
        #expect(!expansion.source.contains("struct PWitness"))
    }
}
