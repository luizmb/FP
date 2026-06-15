// MARK: - Prismatic

/// A type whose enum cases are exposed as a `Prisms` namespace.
///
/// `@Prisms` generates that namespace (`MyEnum.Prisms` + `MyEnum.prism`) and conforms the enum
/// to `Prismatic`, which is what unlocks composable `\.case` key paths via ``PrismFocus``.
public protocol Prismatic {
    /// The generated namespace of per-case `Prism`s (one stored `Prism<Self, Payload>` per case).
    associatedtype Prisms
    /// An instance of the prism namespace.
    static var prism: Prisms { get }
}

// MARK: - PrismFocus

/// A scaffolding wrapper that exists **only** so `\.case` key paths can be formed and composed.
///
/// Swift won't let you write `\MyEnum.someCase` — a key-path literal needs a property/subscript,
/// and enums have neither for their cases. `PrismFocus` is the substitute key-path root: it is
/// `@dynamicMemberLookup`, so writing `\.someCase` against `PrismFocus<Root, Root>` resolves the
/// case through the generated ``Prismatic/prism`` namespace.
///
/// It carries nothing but the `Prism` accumulated from the original `Root` down to the focused
/// `Value`; drilling into a nested case composes that case's prism via `Prism.compose`. Because
/// each step is an ordinary key path between `PrismFocus` values, `\.a.b.c` composes through
/// Swift's native key-path appending.
///
/// You never construct `PrismFocus` directly — form a ``PrismKeyPath`` with `\.case` and turn it
/// back into a `Prism` via ``Prism/init(_:)``.
@dynamicMemberLookup
public struct PrismFocus<Root, Value>: Sendable {
    /// The prism accumulated from `Root` down to `Value`.
    public let prism: Prism<Root, Value>

    public init(prism: Prism<Root, Value>) {
        self.prism = prism
    }

    /// Drills into one of `Value`'s cases, composing its prism onto the accumulated one.
    public subscript<New>(
        dynamicMember member: KeyPath<Value.Prisms, Prism<Value, New>>
    ) -> PrismFocus<Root, New> where Value: Prismatic {
        PrismFocus<Root, New>(prism: prism.compose(Value.prism[keyPath: member]))
    }
}

// MARK: - PrismKeyPath

/// A composable case key path — what `\.case` (and `\.a.b.c`) denotes over a ``Prismatic`` root.
///
/// It is a plain `KeyPath` between ``PrismFocus`` values, so it composes with native key-path
/// appending and recovers to a concrete `Prism` via ``Prism/init(_:)``.
///
/// ```swift
/// let p: Prism<AppAction, AuthAction> = Prism(\.auth)        // \.auth : PrismKeyPath<AppAction, AuthAction>
/// ```
public typealias PrismKeyPath<Root, Value> = KeyPath<PrismFocus<Root, Root>, PrismFocus<Root, Value>>

// MARK: - Recovery

extension Prism {
    /// Recovers the concrete prism denoted by a `\.case` key path.
    ///
    /// Seeds a ``PrismFocus`` with the identity prism and applies the key path, which threads each
    /// case's prism through the dynamic-member subscripts; the result's `prism` is the composition
    /// from `S` down to the focused `A`.
    public init(_ keyPath: PrismKeyPath<S, A>) {
        self = PrismFocus<S, S>(prism: .id)[keyPath: keyPath].prism
    }
}
