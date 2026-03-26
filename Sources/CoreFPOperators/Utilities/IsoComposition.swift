import CoreFP

// MARK: - Iso >>> Iso → Iso

public func >>> <S, A, B>(lhs: Iso<S, A>, rhs: Iso<A, B>) -> Iso<S, B> {
    Iso(
        get: { b in rhs.get(lhs.get(b)) },
        reverseGet: { b in lhs.reverseGet(rhs.reverseGet(b)) }
    )
}

// MARK: - Iso >>> {Lens, Prism, AffineTraversal}

// Iso is stronger than Lens, Prism, and AffineTraversal — delegate by downcasting.

public func >>> <S, A, B>(lhs: Iso<S, A>, rhs: Lens<A, B>) -> Lens<S, B>                    { lhs.asLens >>> rhs }
public func >>> <S, A, B>(lhs: Iso<S, A>, rhs: Prism<A, B>) -> Prism<S, B>                  { lhs.asPrism >>> rhs }
public func >>> <S, A, B>(lhs: Iso<S, A>, rhs: AffineTraversal<A, B>) -> AffineTraversal<S, B> { lhs.asAffineTraversal >>> rhs }

// MARK: - {Lens, Prism, AffineTraversal} >>> Iso

public func >>> <S, A, B>(lhs: Lens<S, A>, rhs: Iso<A, B>) -> Lens<S, B>                    { lhs >>> rhs.asLens }
public func >>> <S, A, B>(lhs: Prism<S, A>, rhs: Iso<A, B>) -> Prism<S, B>                  { lhs >>> rhs.asPrism }
public func >>> <S, A, B>(lhs: AffineTraversal<S, A>, rhs: Iso<A, B>) -> AffineTraversal<S, B> { lhs >>> rhs.asAffineTraversal }

// MARK: - <<< mirrors (right-to-left, delegate to >>>)

public func <<< <S, A, B>(lhs: Iso<A, B>, rhs: Iso<S, A>) -> Iso<S, B>                        { rhs >>> lhs }
public func <<< <S, A, B>(lhs: Iso<A, B>, rhs: Lens<S, A>) -> Lens<S, B>                      { rhs >>> lhs }
public func <<< <S, A, B>(lhs: Iso<A, B>, rhs: Prism<S, A>) -> Prism<S, B>                    { rhs >>> lhs }
public func <<< <S, A, B>(lhs: Iso<A, B>, rhs: AffineTraversal<S, A>) -> AffineTraversal<S, B> { rhs >>> lhs }
public func <<< <S, A, B>(lhs: Lens<A, B>, rhs: Iso<S, A>) -> Lens<S, B>                      { rhs >>> lhs }
public func <<< <S, A, B>(lhs: Prism<A, B>, rhs: Iso<S, A>) -> Prism<S, B>                    { rhs >>> lhs }
public func <<< <S, A, B>(lhs: AffineTraversal<A, B>, rhs: Iso<S, A>) -> AffineTraversal<S, B> { rhs >>> lhs }
