import CoreFP
import CoreFPOperators
import DataStructure

// (<£^>) :: (a -> b) -> Result<Writer<w, a>, e> -> Result<Writer<w, b>, e>
public func <£^> <W: Monoid, A, B, E: Error>(_ fn: @escaping (A) -> B, _ result: Result<Writer<W, A>, E>) -> Result<Writer<W, B>, E> {
    result.mapT(fn)
}

// (<&^>) :: Result<Writer<w, a>, e> -> (a -> b) -> Result<Writer<w, b>, e>
public func <&^> <W: Monoid, A, B, E: Error>(_ result: Result<Writer<W, A>, E>, _ fn: @escaping (A) -> B) -> Result<Writer<W, B>, E> {
    result.mapT(fn)
}
