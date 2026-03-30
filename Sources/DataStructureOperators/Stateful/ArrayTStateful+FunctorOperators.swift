import CoreFPOperators
import DataStructure

// (<£^>) :: (a -> b) -> [Stateful<s, a>] -> [Stateful<s, b>]
public func <£^> <S, A, B>(_ fn: @escaping (A) -> B, _ arr: [Stateful<S, A>]) -> [Stateful<S, B>] {
    arr.mapT(fn)
}

// (<&^>) :: [Stateful<s, a>] -> (a -> b) -> [Stateful<s, b>]
public func <&^> <S, A, B>(_ arr: [Stateful<S, A>], _ fn: @escaping (A) -> B) -> [Stateful<S, B>] {
    arr.mapT(fn)
}
