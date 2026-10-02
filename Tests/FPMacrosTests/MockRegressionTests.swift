// SPDX-License-Identifier: Apache-2.0
import CoreFP
import FPMacros
import Testing

// MARK: - Fixtures

fileprivate enum ParseError: Error, Equatable {
    case invalid
}

fileprivate struct Boom: Error {}

/// Class-bound → `final class` mock with mutable closures.
@Mock
fileprivate protocol Delegate: AnyObject {
    func didFinish(_ value: Int)
    var count: Int { get set }
}

/// `Sendable` → `@Sendable` closures, so the mock crosses isolation domains.
@Mock
fileprivate protocol Fetcher: Sendable {
    func fetch(_ id: Int) async -> String
}

/// `Sendable & AnyObject` → a checked-`Sendable` `final class` with immutable `@Sendable` closures.
@Mock
fileprivate protocol Logger: Sendable & AnyObject {
    func log(_ line: String) -> Int
}

@Mock
fileprivate protocol Toolbox {
    func each(_ body: (Int) -> Void)
    func bump(_ value: inout Int)
    func sum(_ values: Int...) -> Int
    func square(_: Int) -> Int
    func note(_ message: @autoclosure () -> String)
    func parse(_ text: String) throws(ParseError) -> Int
    func retry(_ operation: () throws -> Int) rethrows -> Int
    func describe(_ value: some CustomStringConvertible) -> String
    func find(id: Int) -> String
    func find(id: String) -> String
    var latest: Int { get async throws }
    var cached: Int { get throws(ParseError) }
}

private final class Cell<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}

private func requireSendable<T: Sendable>(_: T.Type) -> Bool { true }

// MARK: - Tests

@Suite("@Mock — regressions")
struct MockRegressionTests {
    @Test func class_bound_protocol_gets_a_class_mock() {
        let seen = Cell(0)
        let mock = DelegateMock(didFinish: { seen.value = $0 }, count: { seen.value }, setCount: { seen.value = $0 })
        let delegate: any Delegate = mock // reference semantics: a `let` mock is still writable
        delegate.count = 3
        delegate.didFinish(5)
        #expect(seen.value == 5)
        #expect(mock.count == 5)
    }

    @Test func sendable_protocol_gets_sendable_closures() async {
        #expect(requireSendable(FetcherMock.self))
        let mock = FetcherMock(fetch: { "item \($0)" })
        let result = await Task { await mock.fetch(1) }.value
        #expect(result == "item 1")
    }

    @Test func sendable_class_bound_protocol_gets_a_sendable_class() {
        #expect(requireSendable(LoggerMock.self))
        #expect(LoggerMock(log: { $0.count }).log("abc") == 3)
    }

    @Test func non_escaping_closure_parameter() {
        let mock = ToolboxMock(each: { body in [1, 2].forEach(body) })
        var total = 0
        mock.each { total += $0 }
        #expect(total == 3)
    }

    @Test func inout_parameter() {
        let mock = ToolboxMock(bump: { $0 += 1 })
        var value = 1
        mock.bump(&value)
        #expect(value == 2)
    }

    @Test func variadic_parameter_arrives_as_array() {
        let mock = ToolboxMock(sum: { $0.reduce(0, +) })
        #expect(mock.sum(1, 2, 3) == 6)
    }

    @Test func unnamed_parameter() {
        let mock = ToolboxMock(square: { $0 * $0 })
        #expect(mock.square(4) == 16)
    }

    @Test func autoclosure_parameter_stays_lazy() {
        let evaluated = Cell(false)
        func message() -> String { evaluated.value = true; return "hi" }
        let ignoring = ToolboxMock(note: { _ in })
        ignoring.note(message())
        #expect(!evaluated.value)
        let captured = Cell("")
        let reading = ToolboxMock(note: { captured.value = $0() })
        reading.note(message())
        #expect(evaluated.value)
        #expect(captured.value == "hi")
    }

    @Test func typed_throws_is_preserved() {
        let mock = ToolboxMock(parse: { (text: String) throws(ParseError) in
            guard let value = Int(text) else { throw .invalid }
            return value
        })
        let ok: Result<Int, ParseError> = Result { () throws(ParseError) in try mock.parse("4") }
        let bad: Result<Int, ParseError> = Result { () throws(ParseError) in try mock.parse("x") }
        #expect(ok == .success(4))
        #expect(bad == .failure(.invalid))
    }

    @Test func rethrows_requirement() {
        let mock = ToolboxMock(retry: { operation in try operation() + 1 })
        #expect(mock.retry { 1 } == 2) // non-throwing argument: no `try` needed
        #expect(throws: Boom.self) { try mock.retry { throw Boom() } }
    }

    @Test func some_parameter_is_erased() {
        let mock = ToolboxMock(describe: { "<\($0)>" })
        #expect(mock.describe(7) == "<7>")
    }

    @Test func same_label_overloads_fall_back_to_types() {
        let mock = ToolboxMock(findWithIdInt: { "int \($0)" }, findWithIdString: { "string \($0)" })
        #expect(mock.find(id: 1) == "int 1")
        #expect(mock.find(id: "a") == "string a")
    }

    @Test func effectful_properties() async throws {
        let mock = ToolboxMock(latest: { 9 }, cached: { () throws(ParseError) in throw .invalid })
        let latest = try await mock.latest
        #expect(latest == 9)
        let cached: Result<Int, ParseError> = Result { () throws(ParseError) in try mock.cached }
        #expect(cached == .failure(.invalid))
    }
}

@Suite("@Mock — diagnostics")
struct MockDiagnosticTests {
    @Test func rejects_private_protocol() {
        assertDiagnostic(
            """
            @Mock
            private protocol P {
                func f()
            }
            """,
            expandsTo: """
            private protocol P {
                func f()
            }
            """,
            message: privateHostMessage("@Mock", "protocols")
        )
    }

    @Test func rejects_indistinguishable_overloads() {
        let expansion = expand("""
        @Mock
        protocol P {
            func make() -> Int
            func make() -> String
        }
        """)
        #expect(expansion.diagnostics.count == 2)
        #expect(expansion.diagnostics.allSatisfy { $0.hasPrefix("@Mock can't give 'make' a unique name") })
        #expect(!expansion.source.contains("struct PMock"))
    }

    @Test func rejects_unsound_generic_erasure() {
        let expansion = expand("""
        @Mock
        protocol P {
            func pair<T: Equatable>(_ a: T, _ b: T)
        }
        """)
        #expect(expansion.diagnostics == [
            "@Mock can only erase generic parameter 'T' to `any` when it is the whole type of exactly one parameter "
                + "(not nested like `[T]`, repeated, or constrained by a `where` same-type requirement)."
        ])
    }

    @Test func still_rejects_real_inheritance() {
        let expansion = expand("""
        @Mock
        protocol P: Sendable & Parent {
            func f()
        }
        """)
        #expect(expansion.diagnostics.count == 1)
        #expect(expansion.diagnostics.first?.hasPrefix("@Mock can't mock a protocol that inherits another protocol") == true)
    }
}
