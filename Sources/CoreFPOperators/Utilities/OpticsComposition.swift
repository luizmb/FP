import CoreFP

// MARK: - Lens compositions

public func >>> <S, A, B>(lhs: Lens<S, A>, rhs: Lens<A, B>) -> Lens<S, B> { lhs.compose(rhs) }
public func >>> <S, A, B>(lhs: Lens<S, A>, rhs: Prism<A, B>) -> AffineTraversal<S, B> { lhs.compose(rhs) }
public func >>> <S, A, B>(lhs: Lens<S, A>, rhs: AffineTraversal<A, B>) -> AffineTraversal<S, B> { lhs.compose(rhs) }

// MARK: - Prism compositions

public func >>> <S, A, B>(lhs: Prism<S, A>, rhs: Prism<A, B>) -> Prism<S, B> { lhs.compose(rhs) }
public func >>> <S, A, B>(lhs: Prism<S, A>, rhs: Lens<A, B>) -> AffineTraversal<S, B> { lhs.compose(rhs) }
public func >>> <S, A, B>(lhs: Prism<S, A>, rhs: AffineTraversal<A, B>) -> AffineTraversal<S, B> { lhs.compose(rhs) }

// MARK: - AffineTraversal compositions

public func >>> <S, A, B>(lhs: AffineTraversal<S, A>, rhs: Lens<A, B>) -> AffineTraversal<S, B> { lhs.compose(rhs) }
public func >>> <S, A, B>(lhs: AffineTraversal<S, A>, rhs: Prism<A, B>) -> AffineTraversal<S, B> { lhs.compose(rhs) }
public func >>> <S, A, B>(lhs: AffineTraversal<S, A>, rhs: AffineTraversal<A, B>) -> AffineTraversal<S, B> { lhs.compose(rhs) }

// MARK: - <<< mirrors (right-to-left, delegate to >>>)

public func <<< <S, A, B>(lhs: Lens<A, B>, rhs: Lens<S, A>) -> Lens<S, B> { rhs >>> lhs }
public func <<< <S, A, B>(lhs: Prism<A, B>, rhs: Lens<S, A>) -> AffineTraversal<S, B> { rhs >>> lhs }
public func <<< <S, A, B>(lhs: AffineTraversal<A, B>, rhs: Lens<S, A>) -> AffineTraversal<S, B> { rhs >>> lhs }
public func <<< <S, A, B>(lhs: Prism<A, B>, rhs: Prism<S, A>) -> Prism<S, B> { rhs >>> lhs }
public func <<< <S, A, B>(lhs: Lens<A, B>, rhs: Prism<S, A>) -> AffineTraversal<S, B> { rhs >>> lhs }
public func <<< <S, A, B>(lhs: AffineTraversal<A, B>, rhs: Prism<S, A>) -> AffineTraversal<S, B> { rhs >>> lhs }
public func <<< <S, A, B>(lhs: Lens<A, B>, rhs: AffineTraversal<S, A>) -> AffineTraversal<S, B> { rhs >>> lhs }
public func <<< <S, A, B>(lhs: Prism<A, B>, rhs: AffineTraversal<S, A>) -> AffineTraversal<S, B> { rhs >>> lhs }
public func <<< <S, A, B>(lhs: AffineTraversal<A, B>, rhs: AffineTraversal<S, A>) -> AffineTraversal<S, B> { rhs >>> lhs }
