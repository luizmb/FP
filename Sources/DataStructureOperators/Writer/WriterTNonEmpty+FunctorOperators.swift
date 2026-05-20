import CoreFP
import CoreFPOperators
import DataStructure

// (<£^>) :: (A -> B) -> Writer<W, NonEmpty<A>> -> Writer<W, NonEmpty<B>>
public func <£^> <W: Monoid, A, B>(_ fn: @escaping @Sendable (A) -> B, _ writer: Writer<W, NonEmpty<A>>) -> Writer<W, NonEmpty<B>> {
    writer.mapT(fn)
}

// (<&^>) :: Writer<W, NonEmpty<A>> -> (A -> B) -> Writer<W, NonEmpty<B>>
public func <&^> <W: Monoid, A, B>(_ writer: Writer<W, NonEmpty<A>>, _ fn: @escaping @Sendable (A) -> B) -> Writer<W, NonEmpty<B>> {
    writer.mapT(fn)
}
