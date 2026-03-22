import DataStructure
import CoreFPOperators
import CoreFP

// (<£^>) :: (a -> b) -> Writer<w, Reader<env, a>> -> Writer<w, Reader<env, b>>
public func <£^> <W: Monoid, Env, A, B>(_ fn: @escaping (A) -> B, _ writer: Writer<W, Reader<Env, A>>) -> Writer<W, Reader<Env, B>> {
    writer.mapT(fn)
}

// (<&^>) :: Writer<w, Reader<env, a>> -> (a -> b) -> Writer<w, Reader<env, b>>
public func <&^> <W: Monoid, Env, A, B>(_ writer: Writer<W, Reader<Env, A>>, _ fn: @escaping (A) -> B) -> Writer<W, Reader<Env, B>> {
    writer.mapT(fn)
}
