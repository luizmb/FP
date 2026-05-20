import CoreFP
import CoreFPOperators
import DataStructure

// (<£^>) :: (a -> b) -> Writer<w, Reader<env, a>> -> Writer<w, Reader<env, b>>
public func <£^> <W: Monoid, Env, A, B>(_ fn: @escaping @Sendable (A) -> B, _ writer: Writer<W, Reader<Env, A>>) -> Writer<W, Reader<Env, B>> {
    writer.mapT(fn)
}

// (<&^>) :: Writer<w, Reader<env, a>> -> (a -> b) -> Writer<w, Reader<env, b>>
public func <&^> <W: Monoid, Env, A, B>(_ writer: Writer<W, Reader<Env, A>>, _ fn: @escaping @Sendable (A) -> B) -> Writer<W, Reader<Env, B>> {
    writer.mapT(fn)
}
