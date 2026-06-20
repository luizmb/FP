// SPDX-License-Identifier: Apache-2.0

// MARK: - IndexedTraversal<S, I, A>

//
// An `IndexedTraversal` is a `Traversal` whose every focus is tagged with an
// *index* `I` — an array position, a dictionary key, an element id. The index
// rides alongside the focus through `getAll` and `modifyMut`, so consumers can
// tell foci apart (e.g. SwiftRex `liftEach` uses it to scope per-element effect
// ids).
//
// Drop the index with `.traversal` to recover a plain `Traversal<S, A>`.

/// A ``Traversal`` whose foci each carry an index `I` (array position, dictionary key, element id).
///
/// `IndexedTraversal<S, I, A>` is the indexed analogue of ``Traversal``: `getAll` returns
/// `(index, focus)` pairs and `modifyMut` hands the index to the mutation. Forget the index with
/// ``traversal`` to get a plain ``Traversal``.
///
/// ```swift
/// let players: IndexedTraversal<[Player], Int, Player> = [Player].eachIndexed
/// players.getAll(roster)            // [(0, p0), (1, p1), …]
/// // keep the position while focusing deeper:
/// let scores = [Player].eachIndexed >>> ^\Player.score   // IndexedTraversal<[Player], Int, Int>
/// ```
///
/// - SeeAlso: ``Traversal``, ``Swift/Array/eachIndexed``, ``Swift/Dictionary/eachValueIndexed``
public struct IndexedTraversal<S, I, A>: Sendable {
    /// Extracts every `(index, focus)` pair from `S`, in traversal order.
    public let getAll: @Sendable (S) -> [(I, A)]

    /// Applies `f` to every focus in place, passing each focus's index alongside.
    public let modifyMut: @Sendable (inout S, (I, inout A) -> Void) -> Void

    /// Full init. Supply the indexed read path (`getAll`) and the indexed in-place write path.
    public init(
        getAll: @escaping @Sendable (S) -> [(I, A)],
        modifyMut: @escaping @Sendable (inout S, (I, inout A) -> Void) -> Void
    ) {
        self.getAll = getAll
        self.modifyMut = modifyMut
    }

    /// Returns every `(index, focus)` pair. Same as ``getAll``, enabling call syntax.
    public func callAsFunction(_ whole: S) -> [(I, A)] { getAll(whole) }

    /// The plain ``Traversal`` that forgets the index.
    public var traversal: Traversal<S, A> {
        Traversal(
            getAll: { getAll($0).map(\.1) },
            modifyMut: { s, f in modifyMut(&s) { _, a in f(&a) } }
        )
    }

    /// Applies a pure, index-aware transform to every focus; returns a new `S`.
    public func over(_ transform: @escaping @Sendable (I, A) -> A) -> @Sendable (S) -> S {
        { s in var c = s; modifyMut(&c) { idx, a in a = transform(idx, a) }; return c }
    }
}

// MARK: - Indexed composition (index-preserving)

//
// Composing an indexed traversal with any plain optic keeps the *outer* index
// and deepens the focus. The result is always an `IndexedTraversal` carrying the
// same `I`. (Composing two indexed traversals would nest indices and is out of
// scope — drop one to a plain `Traversal` via `.traversal` first.)

public extension IndexedTraversal {
    /// Deepens the focus through `other` while preserving each focus's index.
    func compose<B>(_ other: Traversal<A, B>) -> IndexedTraversal<S, I, B> {
        IndexedTraversal<S, I, B>(
            getAll: { s in getAll(s).flatMap { idx, a in other.getAll(a).map { (idx, $0) } } },
            modifyMut: { s, f in modifyMut(&s) { idx, a in other.modifyMut(&a) { b in f(idx, &b) } } }
        )
    }

    /// Deepens the focus through an iso, preserving the index.
    func compose<B>(_ other: Iso<A, B>) -> IndexedTraversal<S, I, B> { compose(other.traversal) }
    /// Deepens the focus through a lens, preserving the index.
    func compose<B>(_ other: Lens<A, B>) -> IndexedTraversal<S, I, B> { compose(other.traversal) }
    /// Deepens the focus through a prism, preserving the index.
    func compose<B>(_ other: Prism<A, B>) -> IndexedTraversal<S, I, B> { compose(other.traversal) }
    /// Deepens the focus through an affine traversal, preserving the index.
    func compose<B>(_ other: AffineTraversal<A, B>) -> IndexedTraversal<S, I, B> { compose(other.traversal) }
}
