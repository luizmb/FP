import DataStructure
import CoreFPOperators
import CoreFP

// (<£^>) :: (a -> b) -> Writer<w, a>? -> Writer<w, b>?
public func <£^> <W: Monoid, A, B>(_ fn: @escaping (A) -> B, _ opt: Writer<W, A>?) -> Writer<W, B>? {
    opt.mapT(fn)
}

// (<&^>) :: Writer<w, a>? -> (a -> b) -> Writer<w, b>?
public func <&^> <W: Monoid, A, B>(_ opt: Writer<W, A>?, _ fn: @escaping (A) -> B) -> Writer<W, B>? {
    opt.mapT(fn)
}
