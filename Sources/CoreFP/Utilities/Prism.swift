// SPDX-License-Identifier: Apache-2.0

// MARK: - Prism<S, A>

//
// A `Prism` focuses on zero or one value of type `A` inside `S` — typically
// one case of an enum. `preview` extracts the focused value if present;
// `review` reconstructs `S` from `A`.
//
// ## In-place mutation and enums
//
// Swift has no `inout` access to an enum's associated value (there is no
// modify coroutine for enum cases), so `tryModifyMut` extracts `A`, mutates it
// and rebuilds `S` via `review`. Extracting leaves two owners of the payload:
// the old `S` and the extracted `A`, so the first write to a CoW payload (an
// array, a dictionary) would copy its whole buffer.
//
// `review` rebuilds `S` from `A` alone, so the old `S` is not needed once `A`
// is out. The synthesised `tryModifyMut` moves `S` into a local with
// `consume` and ends that local's lifetime right after `preview`, leaving `A`
// as the payload's only owner: the mutation happens in place, in debug builds
// too. It is the generic form of `self = .none` before re-assigning the case.
//
// ## lift and tryModifyMut
//
// `lift` packages `tryModifyMut` as an `EndoMut<S>`. When the focus is absent
// the resulting `EndoMut` is a no-op and `S` is left unchanged.
//
// ## compose — operator-free composition
//
// `compose` is the named-function backing for the `>>>` operator.

/// An optic that focuses on zero or one value of type `A` inside `S`.
///
/// A `Prism<S, A>` is the foundational optic for sum types (enums). It models the idea
/// that `S` *might* contain an `A` — the focus is optional. Compare to ``Lens``, which
/// always has a focus, and ``AffineTraversal``, which is the result of composing a lens
/// with a prism.
///
/// ## Core primitives
///
/// | Property | Type | Purpose |
/// |----------|------|---------|
/// | `preview` | `(S) -> A?` | Extract the focused value if present |
/// | `review` | `(A) -> S` | Reconstruct `S` from `A` (the inverse of `preview`) |
/// | `tryModifyMut` | `(inout S, (inout A) -> Void) -> Void` | In-place mutation; no-op if focus absent |
///
/// ## Creating prisms
///
/// Use the free-function ``prism(_:review:)-swift.func`` with an optional `KeyPath`:
///
/// ```swift
/// enum Route { case home, detail(Item) }
///
/// let detailPrism: Prism<Route, Item> = prism(\.detailItem, review: Route.detail)
///
/// // Or with explicit closures:
/// let detailPrism = prism(
///     preview: { if case .detail(let item) = $0 { return item } else { return nil } },
///     review: Route.detail
/// )
/// ```
///
/// ## Using prisms
///
/// ```swift
/// let route = Route.detail(myItem)
/// detailPrism.preview(route)              // Optional(myItem)
/// detailPrism.preview(.home)              // nil
/// detailPrism.review(myItem)              // Route.detail(myItem)
/// detailPrism.over { $0.updated() }(route) // Route.detail(updated item) or unchanged
/// ```
///
/// ## Composition
///
/// Prisms compose with other prisms to yield prisms, and with lenses or affine
/// traversals to yield ``AffineTraversal`` values. Use ``compose(_:)-prism`` directly
/// or the `>>>` operator from `CoreFPOperators`:
///
/// ```swift
/// // Named function:
/// let focusedPrism = outerPrism.compose(innerPrism)
///
/// // Operator form (requires CoreFPOperators):
/// let composed = outerPrism >>> innerPrism
/// ```
///
/// ## Mutation semantics
///
/// Swift has no modify coroutine for enum cases, so `tryModifyMut` moves `A` out of the
/// enum, mutates it and rebuilds `S` via `review`. The old `S` is consumed before the
/// mutation runs, so a CoW payload (an array, a dictionary) is mutated in place rather
/// than copied. ``set(_:_:)`` and ``over(_:)`` take `S` as `consuming`: hand over the
/// value (`consume x`, or a temporary) and they are in place too.
///
/// - Note: For the identity prism (where `S == A`), use ``Prism/id``.
/// - SeeAlso: ``Lens``, ``AffineTraversal``, ``Iso``, ``EndoMut``
public struct Prism<S, A>: Sendable {
    public let preview: @Sendable (S) -> A?
    public let review: @Sendable (A) -> S

    /// Applies `f` to the focused value if present, then reconstructs `S`
    /// via `review`. No-op when the focus is absent.
    ///
    /// The synthesised form consumes the old `S` before `f` runs, so `f` mutates
    /// the payload in place.
    public let tryModifyMut: @Sendable (inout S, (inout A) -> Void) -> Void

    /// Standard 2-closure init. `tryModifyMut` is synthesised from
    /// `preview`+`review` and mutates the payload in place.
    public init(preview: @escaping @Sendable (S) -> A?, review: @escaping @Sendable (A) -> S) {
        self.preview = preview
        self.review = review
        tryModifyMut = { s, f in
            let whole = consume s
            guard var part = preview(whole) else {
                s = whole
                return
            }
            _ = consume whole // end `whole` here so `part` is the payload's only owner
            f(&part)
            s = review(part)
        }
    }

    /// Full init for callers that can supply an explicit `tryModifyMut`.
    public init(
        preview: @escaping @Sendable (S) -> A?,
        review: @escaping @Sendable (A) -> S,
        tryModifyMut: @escaping @Sendable (inout S, (inout A) -> Void) -> Void
    ) {
        self.preview = preview
        self.review = review
        self.tryModifyMut = tryModifyMut
    }

    public func callAsFunction(_ whole: S) -> A? { preview(whole) }

    /// Applies a pure transform if the focus is present; returns a new `S`.
    /// Runs through `tryModifyMut` on the `S` it is handed, so passing a value the
    /// caller no longer needs (`consume x`, a temporary) avoids copying it.
    public func over(_ transform: @escaping @Sendable (A) -> A) -> @Sendable (consuming S) -> S {
        { (s: consuming S) in
            var whole = consume s
            tryModifyMut(&whole) { $0 = transform($0) }
            return whole
        }
    }

    /// Replaces the focused value if present; no-op otherwise.
    public func set(_ s: consuming S, _ a: A) -> S {
        preview(s) == nil ? s : review(a)
    }

    /// Lifts an `EndoMut<A>` into an `EndoMut<S>` focused through this prism.
    /// When the focus is absent the resulting `EndoMut` is a no-op.
    public func lift(_ f: EndoMut<A>) -> EndoMut<S> {
        EndoMut { s in tryModifyMut(&s) { a in f(&a) } }
    }
}

public extension Prism where S == A {
    /// The `id` property.
    static var id: Prism<S, S> {
        Prism(preview: { .some($0) }, review: { $0 }, tryModifyMut: { s, f in f(&s) })
    }
}

/// Builds a `Prism` from an optional-returning `KeyPath` (the preview) and a `review` function.
///
/// ```swift
/// enum Shape { case circle(Double), rectangle(Double, Double) }
///
/// let circlePrism: Prism<Shape, Double> = prism(\.circleRadius, review: Shape.circle)
/// ```
public func prism<S: Sendable, A: Sendable>(_ keyPath: KeyPath<S, A?>, review: @escaping @Sendable (A) -> S) -> Prism<S, A> {
    Prism(preview: { @Sendable s in s[keyPath: keyPath] }, review: review)
}

/// Builds a `Prism` from explicit `preview` and `review` functions.
public func prism<S, A>(preview: @escaping @Sendable (S) -> A?, review: @escaping @Sendable (A) -> S) -> Prism<S, A> {
    Prism(preview: preview, review: review)
}
