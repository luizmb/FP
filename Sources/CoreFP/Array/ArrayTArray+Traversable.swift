public extension Array {
    // traverse :: (a -> [b]) -> [a] -> [[b]]
    // traverse _ []     = [[]]
    // traverse f (x:xs) = liftA2 (:) (f x) (traverse f xs)
    func traverse<B>(_ f: (Element) -> [B]) -> [[B]] {
        reduce([[]] as [[B]]) { acc, x in
            acc.flatMap { arr in f(x).map { arr + [$0] } }
        }
    }

    // sequence :: [[a]] -> [[a]]
    // sequence = traverse id
    func sequence<A>() -> [[A]] where Element == [A] {
        traverse(id)
    }
}
