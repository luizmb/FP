public extension Array {
    // traverse :: (a -> b?) -> [a] -> [b]?
    // traverse _ []     = Just []
    // traverse f (x:xs) = liftA2 (:) (f x) (traverse f xs)
    func traverse<B>(_ f: (Element) -> B?) -> [B]? {
        reduce(.some([])) { acc, x in
            acc.flatMap { arr in f(x).map { arr + [$0] } }
        }
    }

    // traverse :: (a -> Result<b,e>) -> [a] -> Result<[b],e>
    // traverse _ []     = Right []
    // traverse f (x:xs) = liftA2 (:) (f x) (traverse f xs)
    func traverse<B, E: Error>(_ f: (Element) -> Result<B, E>) -> Result<[B], E> {
        reduce(.success([])) { acc, x in
            acc.flatMap { arr in f(x).map { arr + [$0] } }
        }
    }

    // traverse :: (a -> [b]) -> [a] -> [[b]]
    // traverse _ []     = [[]]
    // traverse f (x:xs) = liftA2 (:) (f x) (traverse f xs)
    func traverse<B>(_ f: (Element) -> [B]) -> [[B]] {
        reduce([[]] as [[B]]) { acc, x in
            acc.flatMap { arr in f(x).map { arr + [$0] } }
        }
    }

    // sequence :: [a?] -> [a]?
    // sequence = traverse id
    func sequence<A>() -> [A]? where Element == A? {
        traverse { $0 }
    }

    // sequence :: [Result<a,e>] -> Result<[a],e>
    // sequence = traverse id
    func sequence<A, E: Error>() -> Result<[A], E> where Element == Result<A, E> {
        traverse { $0 }
    }

    // sequence :: [[a]] -> [[a]]
    // sequence = traverse id
    func sequence<A>() -> [[A]] where Element == [A] {
        traverse { $0 }
    }
}
