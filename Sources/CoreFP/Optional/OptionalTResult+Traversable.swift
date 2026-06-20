// SPDX-License-Identifier: Apache-2.0
public extension Optional {
    /// traverse :: (a -> Result<b,e>) -> a? -> Result<b?,e>
    /// traverse _ Nothing  = Right Nothing
    /// traverse f (Just a) = fmap Just (f a)
    func traverse<B, E: Error>(_ f: (Wrapped) -> Result<B, E>) -> Result<B?, E> {
        switch self {
        case .none:
            .success(.none)

        case let .some(a):
            f(a).map(B?.some)
        }
    }

    /// sequence :: Result<a,e>? -> Result<a?,e>
    /// sequence = traverse id
    func sequence<A, E: Error>() -> Result<A?, E> where Wrapped == Result<A, E> {
        traverse(CoreFP.id)
    }
}
