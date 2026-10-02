// SPDX-License-Identifier: Apache-2.0
import CoreFP
import FPMacros
import Testing

// Regression fixtures for how @Lenses / @Iso / @DeriveMonoid read a struct's stored properties.

// MARK: - Property observers are stored

@Lenses(init: .internal)
fileprivate struct Observed {
    var count: Int { didSet { changes += 0 } }
    var label: String { willSet {} }
    var changes = 0
}

@Iso
fileprivate struct ObservedPoint {
    var x: Int { didSet {} }
    var y: Int
}

@DeriveMonoid
fileprivate struct ObservedStats {
    var clicks: Int.Monoids.Sum { didSet {} }
    var ok: Bool.Monoids.And
}

// MARK: - Multi-binding declarations

@Lenses(init: .internal)
fileprivate struct Multi {
    var a, b: Int
    var c = 1, d: String
}

@Iso
fileprivate struct MultiIso { var a, b: Int }

@DeriveMonoid
fileprivate struct MultiStats { var a, b: Int.Monoids.Sum }

// MARK: - Initialised `let` constants aren't memberwise

@Iso
fileprivate struct Versioned {
    let version = 1
    let schema: String = "v1"
    var value: Int
}

@DeriveMonoid
fileprivate struct LabelledStats {
    let label = "stats"
    let unit: String = "clicks"
    var clicks: Int.Monoids.Sum
}

// MARK: - Implicitly-unwrapped optionals

@Lenses(init: .internal)
fileprivate struct LegacyModel {
    var name: String!
    var id: Int
}

@Iso
fileprivate struct LegacyPair {
    var name: String!
    var id: Int
}

// MARK: - Restricted setters

@Lenses(init: .internal)
fileprivate struct Account {
    private(set) var balance: Int
    var owner: String
}

/// `public private(set)` must not yield a public writable lens.
@Lenses(init: .public)
public struct Ledger {
    /// Settable only inside the type.
    public private(set) var total: Int
    /// Settable only inside the module.
    public internal(set) var entries: Int
    /// Freely settable.
    public var name: String
}

// MARK: - Tests

@Suite("Stored-property parsing — observers")
struct ObserverPropertyTests {
    @Test func lenses_count_observed_properties() {
        let value = Observed(count: 1, label: "a")
        #expect(Observed.lens.count.set(value, 5).count == 5)
        #expect(Observed.lens.label.get(value) == "a")
        #expect(value.with(count: 9).count == 9)
    }

    @Test func iso_round_trips_observed_properties() {
        let tuple = ObservedPoint.iso.get(ObservedPoint(x: 1, y: 2))
        #expect(tuple.0 == 1 && tuple.1 == 2)
        #expect(ObservedPoint.iso.reverseGet((3, 4)).x == 3)
    }

    @Test func derive_monoid_combines_observed_properties() {
        let combined = ObservedStats.combine(
            ObservedStats(clicks: .init(2), ok: .init(true)),
            ObservedStats(clicks: .init(3), ok: .init(true))
        )
        #expect(combined.clicks.rawValue == 5)
        #expect(ObservedStats.identity.clicks.rawValue == 0)
    }
}

@Suite("Stored-property parsing — multi-binding")
struct MultiBindingPropertyTests {
    @Test func lenses_include_every_binding() {
        let value = Multi(a: 1, b: 2, d: "x")
        #expect(value.c == 1)
        #expect(Multi.lens.a.set(value, 10).a == 10)
        #expect(Multi.lens.b.get(value) == 2)
        #expect(Multi.lens.d.get(value) == "x")
    }

    @Test func iso_includes_every_binding() {
        let tuple = MultiIso.iso.get(MultiIso(a: 1, b: 2))
        #expect(tuple.0 == 1 && tuple.1 == 2)
    }

    @Test func derive_monoid_includes_every_binding() {
        let combined = MultiStats.combine(MultiStats(a: .init(1), b: .init(2)), MultiStats(a: .init(10), b: .init(20)))
        #expect(combined.a.rawValue == 11)
        #expect(combined.b.rawValue == 22)
    }
}

@Suite("Stored-property parsing — initialised constants")
struct ConstantPropertyTests {
    @Test func iso_skips_initialised_lets() {
        // Single remaining field → the representation collapses to `Int`.
        #expect(Versioned.iso.get(Versioned(value: 7)) == 7)
        #expect(Versioned.iso.reverseGet(8).value == 8)
    }

    @Test func derive_monoid_skips_initialised_lets() {
        let combined = LabelledStats.combine(LabelledStats(clicks: .init(1)), LabelledStats(clicks: .init(2)))
        #expect(combined.clicks.rawValue == 3)
        #expect(LabelledStats.identity.clicks.rawValue == 0)
    }
}

@Suite("Stored-property parsing — implicitly-unwrapped optionals")
struct ImplicitlyUnwrappedPropertyTests {
    @Test func lens_focuses_an_optional() {
        let model = LegacyModel(id: 1) // `name` defaults to nil like any Optional
        let named = LegacyModel.lens.name.set(model, "x")
        #expect(named.name == "x")
        #expect(LegacyModel.lens.name.get(model) == nil)
        #expect(named.with(name: nil).name == nil)
    }

    @Test func iso_represents_an_optional() {
        let tuple = LegacyPair.iso.get(LegacyPair(name: nil, id: 2))
        #expect(tuple.0 == nil && tuple.1 == 2)
    }
}

@Suite("Stored-property parsing — restricted setters")
struct RestrictedSetterTests {
    @Test func private_set_property_keeps_its_lens() {
        let account = Account(balance: 10, owner: "al")
        #expect(Account.lens.balance.set(account, 20).balance == 20)
        #expect(account.with(owner: "bo").balance == 10)
    }

    @Test func public_private_set_property_keeps_its_lens() {
        let ledger = Ledger(total: 1, entries: 2, name: "a")
        #expect(Ledger.lens.total.set(ledger, 5).total == 5)
        #expect(Ledger.lens.entries.set(ledger, 6).entries == 6)
        #expect(ledger.with(name: "b").total == 1)
    }

    @Test func lens_is_capped_to_the_setter_access() {
        let expanded = expand("""
        @Lenses
        public struct Ledger {
            public private(set) var total: Int
            public internal(set) var entries: Int
            public var name: String
        }
        """).source
        #expect(expanded.contains("fileprivate let total: CoreFP.Lens<Ledger, Int>"))
        #expect(expanded.contains("let entries: CoreFP.Lens<Ledger, Int>"))
        #expect(!expanded.contains("public let entries"))
        #expect(expanded.contains("public let name: CoreFP.Lens<Ledger, String>"))
        // `with(...)` is public, so it must not take the restricted-setter properties.
        #expect(expanded.contains("public func with(name: String? = nil) -> Ledger"))
    }
}

@Suite("Stored-property parsing — diagnostics")
struct StoredPropertyDiagnosticTests {
    @Test func derive_monoid_rejects_untyped_stored_property() {
        assertDiagnostic(
            """
            @DeriveMonoid
            struct Stats {
                var a: Int.Monoids.Sum
                var b = Int.Monoids.Sum(5)
            }
            """,
            expandsTo: """
            struct Stats {
                var a: Int.Monoids.Sum
                var b = Int.Monoids.Sum(5)
            }
            """,
            message: "@DeriveMonoid can't read the type of stored property 'b'. "
                + "Add an explicit type annotation (e.g. `var b: SomeType = ...`).",
            line: 4,
            column: 9
        )
    }

    @Test func iso_rejects_untyped_stored_property() {
        assertDiagnostic(
            """
            @Iso
            struct Pair {
                var a: Int
                var b = makeB()
            }
            """,
            expandsTo: """
            struct Pair {
                var a: Int
                var b = makeB()
            }
            """,
            message: "@Iso can't read the type of stored property 'b'. "
                + "Add an explicit type annotation (e.g. `var b: SomeType = ...`).",
            line: 4,
            column: 9
        )
    }

    @Test func derive_monoid_rejects_private_host() {
        assertDiagnostic(
            """
            @DeriveMonoid
            private struct Stats {
                var a: Int.Monoids.Sum
            }
            """,
            expandsTo: """
            private struct Stats {
                var a: Int.Monoids.Sum
            }
            """,
            message: privateHostMessage("@DeriveMonoid", "structs")
        )
    }

    @Test func iso_rejects_private_host() {
        assertDiagnostic(
            """
            @Iso
            private struct Pair {
                var a: Int
            }
            """,
            expandsTo: """
            private struct Pair {
                var a: Int
            }
            """,
            message: privateHostMessage("@Iso", "structs")
        )
    }
}

func privateHostMessage(_ macro: String, _ kind: String) -> String {
    "\(macro) cannot be applied to `private` \(kind). Change the declaration to `fileprivate`, "
        + "`internal`, or higher. (`private` is the only access level whose type-scope semantics "
        + "block the generated declarations; `fileprivate` is functionally identical at file scope.)"
}
