import CoreFP

// (<|>) :: DeferredStream a -> DeferredStream a -> DeferredStream a
// Concatenation: all elements from lhs, then all from rhs.
public func <|> <A: Sendable>(_ lhs: DeferredStream<A>, _ rhs: @autoclosure () -> DeferredStream<A>) -> DeferredStream<A> {
    DeferredStream.alt(lhs, rhs())
}
