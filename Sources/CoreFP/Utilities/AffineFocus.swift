// MARK: - AffineFocus

/// A scaffolding wrapper that exists **only** so mixed `\.field.case.field` key paths can be
/// formed and composed across structs *and* enums.
///
/// Like ``PrismFocus``, this is a substitute key-path root: it is `@dynamicMemberLookup`, so a
/// literal such as `\.user.role.admin` resolves each step against `AffineFocus<Root, Root>`.
/// Where ``PrismFocus`` only drills into enum cases (accumulating a ``Prism``), `AffineFocus`
/// accumulates an ``AffineTraversal`` and drills into **both**:
///
/// - a **struct field** via its `WritableKeyPath` (composing a ``Lens``), and
/// - an **enum case** via the generated ``Prismatic`` namespace (composing a ``Prism``).
///
/// The two subscripts are disambiguated by the compiler with no annotation needed: a stored
/// property can't form a `Prisms` key path, and an enum case can't form a `WritableKeyPath`.
///
/// Because the result is an ``AffineTraversal``, it has `preview`/`set`/`tryModifyMut` but **no
/// `review`** — so this is for reading and in-place mutation (state navigation), not for
/// embedding/lifting actions. Use ``PrismFocus`` when you need `review` (pure-case paths only).
///
/// You never construct `AffineFocus` directly — form an ``AffineKeyPath`` with `\.a.b.c` and turn
/// it into an ``AffineTraversal`` via ``AffineTraversal/init(_:)``.
///
/// ```swift
/// @Prisms enum Role { case admin(Permissions); case guest }
/// struct User { var role: Role }
/// struct App  { var user: User }
///
/// // \.user.role.admin : AffineKeyPath<App, Permissions>
/// let perms: AffineTraversal<App, Permissions> = AffineTraversal(\.user.role.admin)
/// perms.preview(app)            // Optional(...) when the role is .admin, else nil
/// perms.over { $0.elevate() }   // mutates in place only when .admin
/// ```
@dynamicMemberLookup
public struct AffineFocus<Root, Value>: Sendable {
    /// The affine traversal accumulated from `Root` down to `Value`.
    public let traversal: AffineTraversal<Root, Value>

    public init(traversal: AffineTraversal<Root, Value>) {
        self.traversal = traversal
    }

    /// Drills into one of `Value`'s **struct fields**, composing its lens onto the accumulator.
    public subscript<New: Sendable>(
        dynamicMember keyPath: WritableKeyPath<Value, New>
    ) -> AffineFocus<Root, New> where Value: Sendable {
        AffineFocus<Root, New>(traversal: traversal.compose(lens(keyPath)))
    }

    /// Drills into one of `Value`'s **enum cases**, composing its prism onto the accumulator.
    public subscript<New>(
        dynamicMember member: KeyPath<Value.Prisms, Prism<Value, New>>
    ) -> AffineFocus<Root, New> where Value: Prismatic {
        AffineFocus<Root, New>(traversal: traversal.compose(Value.prism[keyPath: member]))
    }
}

// MARK: - AffineKeyPath

/// A composable mixed-optic key path — what `\.a.b.c` denotes over a `Root` whose path threads
/// through struct fields and ``Prismatic`` enum cases.
///
/// It is a plain `KeyPath` between ``AffineFocus`` values, so it composes with native key-path
/// appending and recovers to a concrete ``AffineTraversal`` via ``AffineTraversal/init(_:)``.
public typealias AffineKeyPath<Root, Value> = KeyPath<AffineFocus<Root, Root>, AffineFocus<Root, Value>>

// MARK: - Recovery

extension AffineTraversal {
    /// Recovers the concrete affine traversal denoted by a `\.a.b.c` mixed key path.
    ///
    /// Seeds an ``AffineFocus`` with the identity traversal and applies the key path, threading
    /// each step's lens/prism through the dynamic-member subscripts; the result's `traversal` is
    /// the composition from `S` down to the focused `A`.
    public init(_ keyPath: AffineKeyPath<S, A>) {
        self = AffineFocus<S, S>(traversal: .id)[keyPath: keyPath].traversal
    }
}
