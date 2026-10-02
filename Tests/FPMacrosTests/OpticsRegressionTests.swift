// SPDX-License-Identifier: Apache-2.0
import CoreFP
import FPMacros
import Testing

// MARK: - Nested in a generic type (no `static let` allowed there)

fileprivate enum GenericOuter<T> {
    @Lenses(init: .internal)
    struct Inner { var x: Int }

    @Prisms
    enum Choice {
        case number(Int)
        case nothing
    }
}

@ApplyOptics(recursively: true)
fileprivate struct GenericRoot<T: Sendable> {
    var value: T
    struct Child { var y: Int }
    enum Kind {
        case k(Int)
    }
}

// MARK: - `Sendable` conformance for lens hosts

/// `public` structs never get an implicit `Sendable`, which `CoreFP.lens` needs.
@Lenses(init: .public)
public struct PublicConfig {
    /// Server host.
    public let host: String
    /// Constant: no lens, not in the init.
    public let version = 3
    /// Server port.
    public var port: Int
    /// Timeout in seconds.
    public var timeout = 30
}

/// Already `Sendable` (directly or through a refinement): no second conformance is emitted.
@Lenses(init: .public)
public struct AlreadySendable: Equatable, Sendable {
    /// The focused value.
    public var value: Int
}

/// Generic host: conditionally `Sendable` on the generic parameter its stored properties use.
@Lenses(init: .public)
public struct PublicBox<Wrapped: Sendable> {
    /// The wrapped value.
    public var wrapped: Wrapped
    /// A count.
    public var count: Int
}

/// `@ApplyOptics` drives the same lens generation, so it adds `Sendable` too.
@ApplyOptics(init: .public)
public struct PublicApplied {
    /// A flag.
    public var flag: Bool
}

/// A reference type that isn't `Sendable`.
public final class NonSendableReference {
    /// A mutable value.
    public var value = 0
    /// Creates a reference holding `0`.
    public init() {}
}

/// `.initOnly` emits no lenses, so it needs no `Sendable` and adds none.
@Lenses(.initOnly, init: .public)
public struct InitOnlyHolder {
    /// A non-`Sendable` property.
    public var reference: NonSendableReference
}

private func requireSendable<T: Sendable>(_: T.Type) -> Bool { true }

// MARK: - Tests

@Suite("Optics macros — nested in a generic type")
struct NestedInGenericOpticsTests {
    @Test func lenses_in_generic_outer() {
        let inner = GenericOuter<String>.Inner(x: 1)
        #expect(GenericOuter<String>.Inner.lens.x.set(inner, 4).x == 4)
    }

    @Test func prisms_in_generic_outer() {
        #expect(GenericOuter<String>.Choice.prism.number.preview(.number(3)) == 3)
        #expect(GenericOuter<String>.Choice.prism.number.preview(.nothing) == nil)
    }

    @Test func apply_optics_recursive_on_generic_root() {
        let root = GenericRoot(value: "a")
        #expect(GenericRoot<String>.lens.value.set(root, "b").value == "b")
        #expect(GenericRoot<String>.Child.lens.y.set(.init(y: 1), 2).y == 2)
        #expect(GenericRoot<String>.Kind.prism.k.preview(.k(9)) == 9)
    }
}

@Suite("@Lenses — Sendable conformance")
struct LensesSendableTests {
    @Test func public_struct_gains_sendable_and_lenses_work() {
        #expect(requireSendable(PublicConfig.self))
        let config = PublicConfig(host: "localhost", port: 8_080)
        #expect(PublicConfig.lens.host.set(config, "example.com").host == "example.com")
        #expect(PublicConfig.lens.port.set(config, 9_090).port == 9_090)
        #expect(config.with(port: 9_090).timeout == 30)
    }

    @Test func already_sendable_struct_is_untouched() {
        #expect(requireSendable(AlreadySendable.self))
        #expect(AlreadySendable.lens.value.set(AlreadySendable(value: 1), 2) == AlreadySendable(value: 2))
    }

    @Test func generic_public_struct_is_conditionally_sendable() {
        #expect(requireSendable(PublicBox<Int>.self))
        let box = PublicBox(wrapped: 1, count: 2)
        #expect(PublicBox<Int>.lens.wrapped.set(box, 5).wrapped == 5)
    }

    @Test func apply_optics_adds_sendable_too() {
        #expect(requireSendable(PublicApplied.self))
        #expect(PublicApplied.lens.flag.set(PublicApplied(flag: false), true).flag)
    }

    @Test func init_only_adds_no_conformance() {
        #expect(InitOnlyHolder(reference: NonSendableReference()).reference.value == 0)
        #expect(!expand("@Lenses(.initOnly) public struct S { public var r: Ref }").source.contains("Sendable"))
    }
}
