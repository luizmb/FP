import Foundation

// OptionalTArray: outer = Optional, inner = Array
// Type: [A]? = Optional<[A]>
// Haskell: ListT Maybe

public extension Optional {
    /// flatMapT for Optional<[A]>
    /// (>>=) :: [a]? -> (a -> [b]?) -> [b]?
    /// nil → nil
    /// .some(arr) → mapM fn arr (sequence the results, concatenating on success)
    func flatMapT<A, B>(_ fn: @escaping (A) -> [B]?) -> [B]? where Wrapped == [A] {
        flatMap { arr in
            arr.map(fn).reduce(.some([])) { (acc: [B]?, next: [B]?) in
                acc.flatMap { combined in next.map { combined + $0 } }
            }
        }
    }

    /// Curried bindT for Optional<[A]>
    static func bindT<A, B>(_ fn: @escaping (A) -> [B]?) -> ([A]?) -> [B]? {
        { opt in opt.flatMapT(fn) }
    }
}
