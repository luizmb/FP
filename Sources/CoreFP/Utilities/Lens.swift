// SPDX-License-Identifier: Apache-2.0

// MARK: - Lens<S, A>

//
// A `Lens` focuses on exactly one value of type `A` inside `S`.
//
// ## Pure FP interface
//
// `get` and `set` are the standard lens primitives. `over` applies a pure
// transform and returns a new `S`. These cost one copy of `S` per call —
// which is unavoidable when the contract is to return a new value.
//
// ## Copy-on-Write and in-place mutation
//
// When `S` contains a CoW buffer (Array, Dictionary, String…), passing it
// by value raises the buffer's refcount, triggering an O(n) heap copy on the
// next write even if only one element changes.
//
// `modifyMut` avoids this by taking `S` as `inout`. Swift's Law of Exclusivity
// guarantees no other alias exists during the call, so the buffer stays at
// refcount 1 and mutates in place.
//
// The zero-copy path depends on direct `inout` access into `S`. Using
// `lens(_ keyPath: WritableKeyPath)` achieves this via Swift's modify coroutine:
//
//     modifyMut: { s, f in f(&s[keyPath: keyPath]) }
//
// For manually constructed lenses — those created with a custom setter or
// `lens(_ keyPath: KeyPath, set:)` — `modifyMut` is synthesised from
// `get`+`set` and copies `A` once. The outer `S` is still `inout`, so no
// CoW occurs on `S` itself.
//
// ## Choosing between `over` and `lift`
//
// Use `over` in pure-functional pipelines where you need a new `S`:
//
//     let updated = ageLens.over { $0 + 1 }(person)
//
// Use `lift` when working with `EndoMut` reducers and large CoW states:
//
//     let ageReducer = EndoMut<Int> { $0 += 1 }
//     let personReducer: EndoMut<Person> = lens(\Person.age).lift(ageReducer)
//     personReducer(&person)   // zero-copy when WritableKeyPath-backed
//
// ## compose — operator-free composition
//
// `compose` is the named-function backing for the `>>>` operator. Users who
// import only `CoreFP` can call `lens1.compose(lens2)` instead. All `>>>` and
// `<<<` overloads in `CoreFPOperators` delegate to `compose`.

/// An optic that focuses on exactly one value of type `A` inside a whole `S`.
///
/// A `Lens<S, A>` is the foundational optic for product types (structs, tuples). It
/// guarantees the focused value always exists — unlike ``Prism`` or ``AffineTraversal``,
/// which model optional focuses.
///
/// ## Core primitives
///
/// | Property | Type | Purpose |
/// |----------|------|---------|
/// | `get` | `(S) -> A` | Extract the focused value |
/// | `set` | `(S, A) -> S` | Return a new `S` with the focus replaced |
/// | `modifyMut` | `(inout S, (inout A) -> Void) -> Void` | In-place mutation, avoids CoW copies |
///
/// ## Creating lenses
///
/// The preferred way is via the free-function ``lens(_:)-swift.func`` with a `WritableKeyPath`,
/// which gives zero-copy `modifyMut` through Swift's modify coroutine:
///
/// ```swift
/// let ageLens: Lens<Person, Int> = lens(\.age)
/// // Or using the ^ prefix operator (requires CoreFPOperators):
/// let ageLens: Lens<Person, Int> = ^\Person.age
/// ```
///
/// For `let` properties or computed values, supply an explicit setter:
///
/// ```swift
/// let nameLens: Lens<Person, String> = lens(\.name) { person, name in
///     Person(name: name, age: person.age)
/// }
/// ```
///
/// ## Using lenses
///
/// ```swift
/// let person = Person(name: "Alice", age: 30)
/// ageLens.get(person)                        // 30
/// ageLens.set(person, 31)                    // Person(name: "Alice", age: 31)
/// ageLens.over { $0 + 1 }(person)           // Person(name: "Alice", age: 31)
/// ```
///
/// ## Composition
///
/// Lenses compose left-to-right with ``compose(_:)-lens`` (or the `>>>` operator from
/// `CoreFPOperators`). Composing two lenses yields a lens; composing a lens with a prism
/// or affine traversal yields an ``AffineTraversal``:
///
/// ```swift
/// // Named function (no import needed):
/// let streetLens = lens(\AppState.address).compose(lens(\Address.street))
///
/// // Operator form (requires CoreFPOperators):
/// let streetLens = ^\AppState.address >>> ^\Address.street
/// ```
///
/// ## Zero-copy mutation with EndoMut
///
/// Use ``lift(_:)`` to convert an ``EndoMut``<A> into an ``EndoMut``<S>. When the lens is
/// `WritableKeyPath`-backed, the entire chain is zero-copy:
///
/// ```swift
/// let incrementAge = EndoMut<Int> { $0 += 1 }
/// let personReducer: EndoMut<Person> = lens(\Person.age).lift(incrementAge)
/// personReducer(&person)   // mutates person.age in place, no CoW copies
/// ```
///
/// - Note: For the identity lens (where `S == A`), use ``Lens/id``.
/// - SeeAlso: ``Prism``, ``AffineTraversal``, ``Iso``, ``EndoMut``

public struct Lens<S, A>: Sendable {
    public let get: @Sendable (S) -> A
    public let set: @Sendable (S, A) -> S

    /// Focuses on `A` inside `inout S` without copying `S`.
    ///
    /// For `lens(_ keyPath: WritableKeyPath)`-backed lenses this is zero-copy
    /// end to end (Swift modify coroutine). For manually constructed lenses it
    /// copies `A` once via `get`+`set`; `S` itself is never CoW-copied.
    public let modifyMut: @Sendable (inout S, (inout A) -> Void) -> Void

    /// Standard 2-closure init. `modifyMut` is synthesised from `get`+`set`:
    /// copies `A` once, but keeps `S` as `inout` to avoid CoW on the whole.
    ///
    /// Prefer `init(get:setMut:)` when the write-back can be expressed as
    /// `(inout S, A) -> Void` — that avoids passing `S` by value to `set`.
    public init(get: @escaping @Sendable (S) -> A, set: @escaping @Sendable (S, A) -> S) {
        self.get = get
        self.set = set
        modifyMut = { s, f in
            var part = get(s)
            f(&part)
            s = set(s, part)
        }
    }

    /// Inout-setter init. `set` is synthesised from `setMut`; `modifyMut` keeps
    /// `S` as `inout` throughout — no CoW copy on `S` during write-back.
    ///
    /// Use this when the write-back naturally mutates `S` in place rather than
    /// constructing a brand-new value:
    ///
    /// ```swift
    /// // `let` property — must reconstruct, but keep S as inout:
    /// let nameLens = lens(\.name, setMut: { p, n in
    ///     p = Person(age: p.age, name: n, address: p.address)
    /// })
    /// ```
    public init(get: @escaping @Sendable (S) -> A, setMut: @escaping @Sendable (inout S, A) -> Void) {
        self.get = get
        set = { s, a in var c = s; setMut(&c, a); return c }
        modifyMut = { s, f in
            var part = get(s)
            f(&part)
            setMut(&s, part)
        }
    }

    /// Full init for callers that can supply a more efficient `modifyMut`
    /// (e.g. `lens(_ keyPath: WritableKeyPath)` and optic composition).
    public init(
        get: @escaping @Sendable (S) -> A,
        set: @escaping @Sendable (S, A) -> S,
        modifyMut: @escaping @Sendable (inout S, (inout A) -> Void) -> Void
    ) {
        self.get = get
        self.set = set
        self.modifyMut = modifyMut
    }

    public func callAsFunction(_ whole: S) -> A { get(whole) }

    /// Applies a pure transform; returns a new `S`. Costs one copy of `S`.
    /// Prefer `lift(_:)` when working with `EndoMut` and large CoW values.
    public func over(_ transform: @escaping @Sendable (A) -> A) -> @Sendable (S) -> S {
        { s in set(s, transform(get(s))) }
    }

    /// Lifts an `EndoMut<A>` into an `EndoMut<S>` focused through this lens.
    ///
    /// When this lens is backed by a `WritableKeyPath`, the resulting
    /// `EndoMut<S>` mutates `S` in place with no CoW copies. Compose lenses
    /// before lifting to keep the zero-copy guarantee across the whole chain:
    ///
    /// ```swift
    /// let reducer: EndoMut<AppState> =
    ///     lens(\AppState.items)
    ///         .compose([Item].ix(id: someId))
    ///         .lift(itemReducer)
    /// ```
    public func lift(_ f: EndoMut<A>) -> EndoMut<S> {
        EndoMut { s in modifyMut(&s) { a in f(&a) } }
    }
}

public extension Lens where S == A {
    /// The `id` property.
    static var id: Lens<S, S> {
        Lens(get: { $0 }, set: { _, a in a }, modifyMut: { s, f in f(&s) })
    }
}

/// Lifts a `WritableKeyPath` into a `Lens`.
///
/// Uses Swift's modify coroutine for `modifyMut`, giving zero-copy in-place
/// mutation via `lift(_:)`. The `@Lenses` macro generates this form for all
/// `var` properties automatically.
public func lens<S: Sendable, A: Sendable>(_ keyPath: WritableKeyPath<S, A>) -> Lens<S, A> {
    Lens(
        get: { @Sendable s in s[keyPath: keyPath] },
        set: { @Sendable s, a in var c = s; c[keyPath: keyPath] = a; return c },
        modifyMut: { @Sendable s, f in f(&s[keyPath: keyPath]) }
    )
}

/// Lifts a `KeyPath` into a `Lens` using a manually provided setter.
///
/// Use this for `let` properties or computed values where `WritableKeyPath`
/// is unavailable. `modifyMut` is synthesised from `get`+`set` — it copies
/// `A` once but keeps `S` as `inout`, so no CoW occurs on `S` itself.
///
/// ```swift
/// let nameLens: Lens<Person, String> = lens(\.name) { Person(name: $1, age: $0.age) }
/// ```
public func lens<S: Sendable, A: Sendable>(_ keyPath: KeyPath<S, A>, set: @escaping @Sendable (S, A) -> S) -> Lens<S, A> {
    Lens(get: { @Sendable s in s[keyPath: keyPath] }, set: set)
}

/// Lifts a `KeyPath` into a `Lens` using an inout setter.
///
/// Prefer this over `lens(_:set:)` when the write-back can be expressed as a
/// direct mutation of `S` — `modifyMut` never passes `S` by value, so no
/// CoW copy occurs on `S` during write-back.
///
/// ```swift
/// let nameLens = lens(\.name, setMut: { p, n in
///     p = Person(age: p.age, name: n, address: p.address)
/// })
/// ```
public func lens<S: Sendable, A: Sendable>(_ keyPath: KeyPath<S, A>, setMut: @escaping @Sendable (inout S, A) -> Void) -> Lens<S, A> {
    Lens(get: { @Sendable s in s[keyPath: keyPath] }, setMut: setMut)
}
