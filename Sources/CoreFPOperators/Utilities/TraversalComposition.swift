// SPDX-License-Identifier: Apache-2.0
import CoreFP

// MARK: - X >>> Traversal  (every combo collapses to Traversal)

/// `>>>` overload for `X >>> Traversal  (every combo collapses to Traversal)`.
public func >>> <S, A, B>(lhs: Iso<S, A>, rhs: Traversal<A, B>) -> Traversal<S, B> { lhs.compose(rhs) }
/// `>>>` overload for `X >>> Traversal  (every combo collapses to Traversal)`.
public func >>> <S, A, B>(lhs: Lens<S, A>, rhs: Traversal<A, B>) -> Traversal<S, B> { lhs.compose(rhs) }
/// `>>>` overload for `X >>> Traversal  (every combo collapses to Traversal)`.
public func >>> <S, A, B>(lhs: Prism<S, A>, rhs: Traversal<A, B>) -> Traversal<S, B> { lhs.compose(rhs) }
/// `>>>` overload for `X >>> Traversal  (every combo collapses to Traversal)`.
public func >>> <S, A, B>(lhs: AffineTraversal<S, A>, rhs: Traversal<A, B>) -> Traversal<S, B> { lhs.compose(rhs) }
/// `>>>` overload for `X >>> Traversal  (every combo collapses to Traversal)`.
public func >>> <S, A, B>(lhs: Traversal<S, A>, rhs: Traversal<A, B>) -> Traversal<S, B> { lhs.compose(rhs) }

// MARK: - Traversal >>> X

/// `>>>` overload for `Traversal >>> X`.
public func >>> <S, A, B>(lhs: Traversal<S, A>, rhs: Iso<A, B>) -> Traversal<S, B> { lhs.compose(rhs) }
/// `>>>` overload for `Traversal >>> X`.
public func >>> <S, A, B>(lhs: Traversal<S, A>, rhs: Lens<A, B>) -> Traversal<S, B> { lhs.compose(rhs) }
/// `>>>` overload for `Traversal >>> X`.
public func >>> <S, A, B>(lhs: Traversal<S, A>, rhs: Prism<A, B>) -> Traversal<S, B> { lhs.compose(rhs) }
/// `>>>` overload for `Traversal >>> X`.
public func >>> <S, A, B>(lhs: Traversal<S, A>, rhs: AffineTraversal<A, B>) -> Traversal<S, B> { lhs.compose(rhs) }

// MARK: - <<< mirrors (right-to-left, delegate to >>>)

/// `func` for `<<< mirrors (right-to-left, delegate to >>>)`.
public func <<< <S, A, B>(lhs: Traversal<A, B>, rhs: Iso<S, A>) -> Traversal<S, B> { rhs >>> lhs }
/// `func` for `<<< mirrors (right-to-left, delegate to >>>)`.
public func <<< <S, A, B>(lhs: Traversal<A, B>, rhs: Lens<S, A>) -> Traversal<S, B> { rhs >>> lhs }
/// `func` for `<<< mirrors (right-to-left, delegate to >>>)`.
public func <<< <S, A, B>(lhs: Traversal<A, B>, rhs: Prism<S, A>) -> Traversal<S, B> { rhs >>> lhs }
/// `func` for `<<< mirrors (right-to-left, delegate to >>>)`.
public func <<< <S, A, B>(lhs: Traversal<A, B>, rhs: AffineTraversal<S, A>) -> Traversal<S, B> { rhs >>> lhs }
/// `func` for `<<< mirrors (right-to-left, delegate to >>>)`.
public func <<< <S, A, B>(lhs: Traversal<A, B>, rhs: Traversal<S, A>) -> Traversal<S, B> { rhs >>> lhs }
/// `func` for `<<< mirrors (right-to-left, delegate to >>>)`.
public func <<< <S, A, B>(lhs: Iso<A, B>, rhs: Traversal<S, A>) -> Traversal<S, B> { rhs >>> lhs }
/// `func` for `<<< mirrors (right-to-left, delegate to >>>)`.
public func <<< <S, A, B>(lhs: Lens<A, B>, rhs: Traversal<S, A>) -> Traversal<S, B> { rhs >>> lhs }
/// `func` for `<<< mirrors (right-to-left, delegate to >>>)`.
public func <<< <S, A, B>(lhs: Prism<A, B>, rhs: Traversal<S, A>) -> Traversal<S, B> { rhs >>> lhs }
/// `func` for `<<< mirrors (right-to-left, delegate to >>>)`.
public func <<< <S, A, B>(lhs: AffineTraversal<A, B>, rhs: Traversal<S, A>) -> Traversal<S, B> { rhs >>> lhs }

// MARK: - IndexedTraversal >>> X  (index-preserving; result stays IndexedTraversal)

/// `>>>` overload for `IndexedTraversal >>> X  (index-preserving; result stays IndexedTraversal)`.
public func >>> <S, I, A, B>(lhs: IndexedTraversal<S, I, A>, rhs: Iso<A, B>) -> IndexedTraversal<S, I, B> { lhs.compose(rhs) }
/// `>>>` overload for `IndexedTraversal >>> X  (index-preserving; result stays IndexedTraversal)`.
public func >>> <S, I, A, B>(lhs: IndexedTraversal<S, I, A>, rhs: Lens<A, B>) -> IndexedTraversal<S, I, B> { lhs.compose(rhs) }
/// `>>>` overload for `IndexedTraversal >>> X  (index-preserving; result stays IndexedTraversal)`.
public func >>> <S, I, A, B>(lhs: IndexedTraversal<S, I, A>, rhs: Prism<A, B>) -> IndexedTraversal<S, I, B> { lhs.compose(rhs) }
/// `>>>` overload for `IndexedTraversal >>> X  (index-preserving; result stays IndexedTraversal)`.
public func >>> <S, I, A, B>(lhs: IndexedTraversal<S, I, A>, rhs: AffineTraversal<A, B>) -> IndexedTraversal<S, I, B> { lhs.compose(rhs) }
/// `>>>` overload for `IndexedTraversal >>> X  (index-preserving; result stays IndexedTraversal)`.
public func >>> <S, I, A, B>(lhs: IndexedTraversal<S, I, A>, rhs: Traversal<A, B>) -> IndexedTraversal<S, I, B> { lhs.compose(rhs) }

// MARK: - <<< mirrors for IndexedTraversal

/// `func` for `<<< mirrors for IndexedTraversal`.
public func <<< <S, I, A, B>(lhs: Iso<A, B>, rhs: IndexedTraversal<S, I, A>) -> IndexedTraversal<S, I, B> { rhs >>> lhs }
/// `func` for `<<< mirrors for IndexedTraversal`.
public func <<< <S, I, A, B>(lhs: Lens<A, B>, rhs: IndexedTraversal<S, I, A>) -> IndexedTraversal<S, I, B> { rhs >>> lhs }
/// `func` for `<<< mirrors for IndexedTraversal`.
public func <<< <S, I, A, B>(lhs: Prism<A, B>, rhs: IndexedTraversal<S, I, A>) -> IndexedTraversal<S, I, B> { rhs >>> lhs }
/// `func` for `<<< mirrors for IndexedTraversal`.
public func <<< <S, I, A, B>(lhs: AffineTraversal<A, B>, rhs: IndexedTraversal<S, I, A>) -> IndexedTraversal<S, I, B> { rhs >>> lhs }
/// `func` for `<<< mirrors for IndexedTraversal`.
public func <<< <S, I, A, B>(lhs: Traversal<A, B>, rhs: IndexedTraversal<S, I, A>) -> IndexedTraversal<S, I, B> { rhs >>> lhs }
