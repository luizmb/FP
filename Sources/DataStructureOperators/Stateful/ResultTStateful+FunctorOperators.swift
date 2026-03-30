import DataStructure
import CoreFPOperators

// (<£^>) :: (a -> b) -> Result<Stateful<s, a>, e> -> Result<Stateful<s, b>, e>
public func <£^> <S, A, B, E: Error>(_ fn: @escaping (A) -> B, _ result: Result<Stateful<S, A>, E>) -> Result<Stateful<S, B>, E> {
    result.mapT(fn)
}

// (<&^>) :: Result<Stateful<s, a>, e> -> (a -> b) -> Result<Stateful<s, b>, e>
public func <&^> <S, A, B, E: Error>(_ result: Result<Stateful<S, A>, E>, _ fn: @escaping (A) -> B) -> Result<Stateful<S, B>, E> {
    result.mapT(fn)
}
