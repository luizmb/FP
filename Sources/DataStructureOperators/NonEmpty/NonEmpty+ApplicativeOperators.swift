import CoreFPOperators
import DataStructure

// MARK: - Applicative operators for NonEmpty

// (<*>) :: NonEmpty<(A -> B)> -> NonEmpty<A> -> NonEmpty<B>
public func <*> <A, B>(
    _ nf: NonEmpty<(A) -> B>,
    _ na: NonEmpty<A>
) -> NonEmpty<B> {
    NonEmpty<B>.apply(nf, na)
}

// (*>) :: NonEmpty<A> -> NonEmpty<B> -> NonEmpty<B>
public func *> <A, B>(
    _ lhs: NonEmpty<A>,
    _ rhs: NonEmpty<B>
) -> NonEmpty<B> {
    lhs.seqRight(rhs)
}

// (<*) :: NonEmpty<A> -> NonEmpty<B> -> NonEmpty<A>
public func <* <A, B>(
    _ lhs: NonEmpty<A>,
    _ rhs: NonEmpty<B>
) -> NonEmpty<A> {
    lhs.seqLeft(rhs)
}
