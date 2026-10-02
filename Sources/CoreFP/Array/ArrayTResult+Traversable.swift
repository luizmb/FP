// SPDX-License-Identifier: Apache-2.0
public extension Array {
    /// traverse :: (a -> Result<b,e>) -> [a] -> Result<[b],e>
    /// traverse _ []     = Right []
    /// traverse f (x:xs) = liftA2 (:) (f x) (traverse f xs)
    ///
    /// O(n): appends into one buffer and stops calling `f` at the first failure.
    func traverse<B, E: Error>(_ f: (Element) -> Result<B, E>) -> Result<[B], E> {
        var result: [B] = []
        result.reserveCapacity(count)
        for element in self {
            switch f(element) {
            case let .success(b):
                result.append(b)

            case let .failure(error):
                return .failure(error)
            }
        }
        return .success(result)
    }

    /// sequence :: [Result<a,e>] -> Result<[a],e>
    /// sequence = traverse id
    func sequence<A, E: Error>() -> Result<[A], E> where Element == Result<A, E> {
        traverse(CoreFP.id)
    }
}
