import DataStructure
import CoreFPOperators

// (<£^>) :: (a -> b) -> Stateful<s, a>? -> Stateful<s, b>?
public func <£^> <S, A, B>(_ fn: @escaping (A) -> B, _ opt: Stateful<S, A>?) -> Stateful<S, B>? {
    opt.mapT(fn)
}

// (<&^>) :: Stateful<s, a>? -> (a -> b) -> Stateful<s, b>?
public func <&^> <S, A, B>(_ opt: Stateful<S, A>?, _ fn: @escaping (A) -> B) -> Stateful<S, B>? {
    opt.mapT(fn)
}
