// SPDX-License-Identifier: Apache-2.0

// MARK: - AffineTraversal<S, A>

//
// An `AffineTraversal` focuses on zero or one value of type `A` inside `S`.
// It is the result of composing a `Lens` with a `Prism` (in either order):
// the whole `S` is always present (Lens property), but the focus may be absent
// (Prism property).
//
// ## In-place mutation
//
// `tryModifyMut` applies a mutation to the focused `A` in place, keeping
// `S` as `inout` throughout. When absent, it is a no-op.
//
// The copy cost depends on how the optic was constructed:
//
//   - `affineTraversal(_ keyPath: WritableKeyPath<S, A?>)`: copies `A` once
//     (extracted from the optional), then writes back into `inout S`. No CoW
//     on `S`.
//
//   - `[T].ix(index)` / `[T].ix(id:)`: accesses the element directly via
//     `inout collection[index]` — zero-copy for the collection buffer.
//
//   - `[K:V].ix(key:)`: copies `Value` once (extracted from the optional
//     subscript); no CoW on the dictionary buffer.
//
//   - 2-closure init (manual construction): `tryModifyMut` is synthesised
//     from `preview`+`set`. Copies `A` once; `S` is kept `inout`.
//
// ## lift and compose
//
// `lift` turns an `EndoMut<A>` into an `EndoMut<S>`. When the focus is absent
// the result is a no-op.
//
// `compose` is the named-function backing for the `>>>` operator, available
// without importing `CoreFPOperators`.

/// An optic that focuses on zero or one value of type `A` inside a whole `S`.
///
/// `AffineTraversal<S, A>` is the result of composing a ``Lens`` with a ``Prism`` (in
/// either order). It combines the "always-present whole" guarantee of a lens with the
/// "maybe-present focus" of a prism.
///
/// ## Core primitives
///
/// | Property | Type | Purpose |
/// |----------|------|---------|
/// | `preview` | `(S) -> A?` | Extract the focused value if present |
/// | `set` | `(S, A) -> S` | Return a new `S` with the focus replaced (no-op if absent) |
/// | `tryModifyMut` | `(inout S, (inout A) -> Void) -> Void` | In-place mutation; no-op if focus absent |
///
/// ## Creating affine traversals
///
/// The most common source is composing a ``Lens`` with a ``Prism``:
///
/// ```swift
/// // Via composition (requires CoreFPOperators for >>>):
/// let activeItemTraversal: AffineTraversal<AppState, Item> =
///     ^\AppState.route >>> routeDetailPrism
///
/// // From a WritableKeyPath to an optional property:
/// let currentUserTraversal: AffineTraversal<AppState, User> =
///     affineTraversal(\AppState.currentUser)
/// ```
///
/// Collection subscripts (`ix`) also produce affine traversals:
///
/// ```swift
/// [Int].ix(2)                                    // AffineTraversal<[Int], Int>
/// [Item].ix(id: someId)                          // AffineTraversal<[Item], Item>
/// [String: Int].ix(key: "count")                 // AffineTraversal<[String: Int], Int>
/// ```
///
/// ## Using affine traversals
///
/// ```swift
/// let traversal: AffineTraversal<[Int], Int> = [Int].ix(1)
/// traversal.preview([10, 20, 30])                // Optional(20)
/// traversal.preview([10])                        // nil (out of bounds)
/// traversal.set([10, 20, 30], 99)               // [10, 99, 30]
/// traversal.over { $0 * 2 }([10, 20, 30])       // [10, 40, 30]
/// ```
///
/// ## Composition
///
/// Affine traversals compose with lenses, prisms, and other affine traversals to
/// yield affine traversals. Use ``compose(_:)-affinetraversal-lens`` directly or the
/// `>>>` operator from `CoreFPOperators`.
///
/// ## CoW cost
///
/// The copy cost depends on the backing optic:
/// - `ix` on `MutableCollection` → zero-copy (direct `inout` access)
/// - `ix` on `Dictionary` → copies `Value` once
/// - `WritableKeyPath` to optional → copies `A` once
/// - Manual construction → copies `A` once via `preview`+`set`
///
/// - Note: For the identity affine traversal (where `S == A`), use ``AffineTraversal/id``.
/// - SeeAlso: ``Lens``, ``Prism``, ``Iso``, ``EndoMut``
public struct AffineTraversal<S, A>: Sendable {
    public let preview: @Sendable (S) -> A?
    public let set: @Sendable (S, A) -> S

    /// Applies `f` to the focused value if present. No-op when the focus is
    /// absent. `S` is kept `inout` throughout; copy cost depends on the
    /// specific optic — see the file-level comment.
    public let tryModifyMut: @Sendable (inout S, (inout A) -> Void) -> Void

    /// Standard 2-closure init. `tryModifyMut` is synthesised from
    /// `preview`+`set`: copies `A` once, keeps `S` as `inout`.
    ///
    /// Prefer `init(preview:setMut:)` when the write-back can be expressed as
    /// `(inout S, A) -> Void` — that avoids passing `S` by value to `set`.
    public init(preview: @escaping @Sendable (S) -> A?, set: @escaping @Sendable (S, A) -> S) {
        self.preview = preview
        self.set = set
        tryModifyMut = { s, f in
            guard var part = preview(s) else { return }
            f(&part)
            s = set(s, part)
        }
    }

    /// Full init for callers that can supply a more efficient `tryModifyMut`
    /// (e.g. `ix` and `affineTraversal(_ keyPath: WritableKeyPath)`).
    public init(
        preview: @escaping @Sendable (S) -> A?,
        set: @escaping @Sendable (S, A) -> S,
        tryModifyMut: @escaping @Sendable (inout S, (inout A) -> Void) -> Void
    ) {
        self.preview = preview
        self.set = set
        self.tryModifyMut = tryModifyMut
    }

    /// Inout-setter init. `set` is synthesised from `setMut` (with a focus-absent
    /// guard); `tryModifyMut` keeps `S` as `inout` throughout — no CoW copy on
    /// `S` during write-back.
    ///
    /// `setMut` is only called when `preview` returns a non-`nil` value; it is
    /// the caller's responsibility to ensure the mutation is valid in that case.
    ///
    /// ```swift
    /// // Focus on a `let` optional property, reconstructing S on write:
    /// let userTraversal = AffineTraversal<AppState, User>(
    ///     preview: { $0.currentUser },
    ///     setMut: { state, user in state = AppState(currentUser: user, other: state.other) }
    /// )
    /// ```
    public init(preview: @escaping @Sendable (S) -> A?, setMut: @escaping @Sendable (inout S, A) -> Void) {
        self.preview = preview
        set = { s, a in
            guard preview(s) != nil else { return s }
            var c = s; setMut(&c, a); return c
        }
        tryModifyMut = { s, f in
            guard var part = preview(s) else { return }
            f(&part)
            setMut(&s, part)
        }
    }

    public func callAsFunction(_ whole: S) -> A? { preview(whole) }

    /// Applies a pure transform if the focus is present; returns a new `S`.
    /// Prefer `lift(_:)` when working with `EndoMut` and large CoW states.
    public func over(_ transform: @escaping @Sendable (A) -> A) -> @Sendable (S) -> S {
        { s in preview(s).map { set(s, transform($0)) } ?? s }
    }

    /// Lifts an `EndoMut<A>` into an `EndoMut<S>` focused through this traversal.
    /// When the focus is absent the resulting `EndoMut` is a no-op.
    public func lift(_ f: EndoMut<A>) -> EndoMut<S> {
        EndoMut { s in tryModifyMut(&s) { a in f(&a) } }
    }
}

public extension AffineTraversal where S == A {
    /// The `id` property.
    static var id: AffineTraversal<S, S> {
        AffineTraversal(preview: { .some($0) }, set: { _, a in a }, tryModifyMut: { s, f in f(&s) })
    }
}

/// Lifts a `WritableKeyPath` to an optional property into an `AffineTraversal`.
/// Preview reads the optional; set writes the non-nil focus back as `.some`.
///
/// `tryModifyMut` copies `A` once (extracted from the optional) then writes
/// back into `inout S` — no CoW on `S`.
///
/// ```swift
/// affineTraversal(\[Int][safe: 2])  // AffineTraversal<[Int], Int> — same as ix(2)
/// ```
public func affineTraversal<S: Sendable, A: Sendable>(_ keyPath: WritableKeyPath<S, A?>) -> AffineTraversal<S, A> {
    AffineTraversal(
        preview: { @Sendable s in s[keyPath: keyPath] },
        set: { @Sendable s, a in var c = s; c[keyPath: keyPath] = a; return c },
        tryModifyMut: { @Sendable s, f in
            guard var value = s[keyPath: keyPath] else { return }
            f(&value)
            s[keyPath: keyPath] = value
        }
    )
}
